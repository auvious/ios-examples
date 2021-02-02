//
//  GenesysCloudGuestChatService.swift
//  GenesysCloudSimpleConference
//
//  Created by Epimenidis Voutsakis on 29/1/21.
//

import RxSwift
import os

protocol TicketProgressDelegate {
    /**
     Called when the websocket with Genesys is connected
     */
    func onSocketConnected()
    /**
     Called when our chat request is queued on Genesys ACD queue
     */
    func onQueued()
    /**
     Called when an agent answers the chat
     */
    func onAgentConnected() -> String
    /**
     Called when the agent sends a ticket
     */
    func onTicket(_ ticket: String)
    /**
     Called when a non-recoverable error has occured
     */
    func onError(_ error: Error)
}

protocol InternalChatDelegate {
    func onDataReceived(_ data: Data)
    func onMessageReceived(_ message: String)
    func onConnected(_ chat: GenesysCloudGuestChatTicketProvider)
    func onError(_ error: Error)
}

struct CustomerDisconnectedError: LocalizedError {
    let conversationId: String
    let memberId: String

    var errorDescription: String? {
        get { "customer with member id \(memberId) disconnected from conversation with id \(conversationId)" }
    }
}

class GenesysCloudGuestChatTicketProvider: NSObject, URLSessionWebSocketDelegate {
    struct GenesysCloudGuestChatError: LocalizedError {
        let message: String

        var errorDescription: String? {
            get { "\(GenesysCloudGuestChatTicketProvider.self) error with message: \(message)" }
        }
    }

    struct RoutingTarget: Codable {
        var targetType: String
        var targetAddress: String
    }

    struct MemberInfo: Codable {
        var displayName: String
        var avatarImageUrl: String?
        var lastName: String?
        var firstName: String?
        var email: String?
        var phoneNumber: String?
        var customFields: Dictionary<String, String>?
    }

    struct ChatRequest: Codable {
        var organizationId: String
        var deploymentId: String
        var routingTarget: RoutingTarget
        var memberInfo: MemberInfo
    }

    struct Member: Codable {
        var id: String
    }

    struct ChatResponse: Codable {
        var id: String
        var jwt: String
        var eventStreamUri: String
        var member: Member
    }

    typealias ChatInfo = ChatResponse

    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()

    static func create(_ delegate: TicketProgressDelegate?) -> Single<GenesysCloudGuestChatTicketProvider> {
        return createChat()
            .map({ chatResponse in
                GenesysCloudGuestChatTicketProvider(chatResponse, delegate)
            })
    }

    private static func createChat() -> Single<ChatResponse> {
        return Single.create { single in
            let pcEnvironment = Options.get("pcEnvironment") ?? "mypurecloud.com"

            var request = URLRequest(url: URL(string: "https://api.\(pcEnvironment)/api/v2/webchat/guest/conversations")!)
            request.httpMethod = "POST"

            let targetType = Options.get("targetType") ?? "queue"
            let targetAddress = Options.get("targetAddress") ?? "AppFoundry"

            let routingTarget = RoutingTarget(targetType: targetType, targetAddress: targetAddress)

            let customFields = [
                "some_field": "arbitrary data",
                "another_field": "more arbitrary data",
                "auvious.origin.widget.videoCall": "iOS App",
                "auvious.origin.widget.conversation.type": "video"
            ]
            let displayName = Options.get("displayName") ?? "Bender Bending Rodriguez"
            let firstName = Options.get("firstName") ?? "Bender"
            let lastName = Options.get("lastName") ?? "Rodriguez"
            let email = Options.get("email") ?? "bender.bending.rodriguez@example.com"
            let phoneNumber = Options.get("phoneNumber") ?? "+66 666666"
            let avatarImageUrl = Options.get("avatarImageUrl") ?? "https://en.wikipedia.org/wiki/Bender_(Futurama)#/media/File:Bender_Rodriguez.png"

            let memberInfo = MemberInfo(displayName: displayName, avatarImageUrl: avatarImageUrl, lastName: lastName, firstName: firstName, email: email, phoneNumber: phoneNumber, customFields: customFields)

            let organizationId = Options.get("organizationId") ?? "unknown"
            let deploymentId = Options.get("deploymentId") ?? "unknown"

            let chatRequest = ChatRequest(organizationId: organizationId, deploymentId: deploymentId, routingTarget: routingTarget, memberInfo: memberInfo)

            request.httpBody = try? encoder.encode(chatRequest)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let session = URLSession.shared

            let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                guard error == nil else {
                    single(.failure(GenesysCloudGuestChatError(message: "chat request failed: \(error?.localizedDescription ?? "unknown")")))
                    return
                }

                guard response != nil else {
                    single(.failure(GenesysCloudGuestChatError(message: "chat request failed: nil response")))
                    return
                }

                guard response is HTTPURLResponse else {
                    single(.failure(GenesysCloudGuestChatError(message: "chat request failed: no http response")))
                    return
                }

                let httpResponse = response as! HTTPURLResponse

                guard httpResponse.statusCode == 200 else {
                    single(.failure(GenesysCloudGuestChatError(message: "chat request failed: status code \(httpResponse.statusCode)")))
                    return
                }

                do {
                    let chatResponse = try decoder.decode(ChatResponse.self, from: data!)
                    single(.success(chatResponse))
                } catch {
                    single(.failure(GenesysCloudGuestChatError(message: "json parser error \(error.localizedDescription)")))
                }
            })

            task.resume()

            return Disposables.create { }
        }
    }

    private let chatInfo: ChatInfo
    private var socket: URLSessionWebSocketTask?
    private let delegate: TicketProgressDelegate?
    private let internalDelegate: InternalChatDelegate
    //private let single:(Result<String, Error>) -> Void

    init(_ chatInfo: ChatInfo, _ delegate: TicketProgressDelegate?) {
        self.chatInfo = chatInfo
        self.delegate = delegate
        self.internalDelegate = MyInternalChatDelegate()
        super.init()
    }

    func id() -> String {
        return chatInfo.id
    }

    func memberId() -> String {
        return chatInfo.member.id
    }

    func jwt() -> String {
        return chatInfo.jwt
    }

    func connect() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())

        self.socket = session.webSocketTask(with: URL(string: chatInfo.eventStreamUri)!)
        self.listen()
        self.socket!.resume()
    }

    func disconnect() {
        self.socket?.cancel()
        let conversationId = self.id()
        let customerId = self.memberId()
        let pcEnvironment = Options.get("pcEnvironment") ?? "mypurecloud.com"
        var request = URLRequest(url: URL(string: "https://api.\(pcEnvironment)/api/v2/webchat/guest/conversations/\(conversationId)/members/\(customerId)")!)
        request.httpMethod = "DELETE"

        request.addValue("Bearer \(self.jwt())", forHTTPHeaderField: "Authorization")

        let session = URLSession.shared

        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            let httpResponse = response as! HTTPURLResponse

            guard [200, 204].contains(httpResponse.statusCode) else {
                os_log("member delete failed: status code \(httpResponse.statusCode)")
                return
            }
        })
        task.resume()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.internalDelegate.onConnected(self)
    }

    private func listen() {
        self.socket!.receive { result in
            switch result {
            case .failure(let error):
                self.delegateOnError(error)
                return
            case .success(let message):
                switch message {
                case .data(let data):
                    self.internalDelegate.onDataReceived(data)
                case .string(let str):
                    self.internalDelegate.onMessageReceived(str)
                @unknown default:
                    break
                }
            }
            self.listen()
        }
    }

    private var hasDelegateBeenSignalledWithOnError = false
    private func delegateOnError(_ error: Error) {
        guard !hasDelegateBeenSignalledWithOnError else {
            return
        }
        self.delegate?.onError(error)
        hasDelegateBeenSignalledWithOnError = true
        disconnect()
    }

    private var hasDelegateBeenSignalledForQueued = false
    private func delegateOnQueued() {
        guard !hasDelegateBeenSignalledForQueued else {
            return
        }

        delegate?.onQueued()
        hasDelegateBeenSignalledForQueued = true
    }

    private var hasDelegateBeenSignalledForAgentConnected = false
    private func delegateOnAgentConnected() -> String? {
        guard !hasDelegateBeenSignalledForAgentConnected else {
            return nil
        }

        let notice = delegate?.onAgentConnected()
        hasDelegateBeenSignalledForAgentConnected = true
        return notice
    }

    /**
     Called when a ticket is sent by the agent.

     - Parameter ticket: ticket sent by the agent
     */
    private func delegateOnTicket(_ ticket: String) {
        delegate?.onTicket(ticket)
    }

    class MyInternalChatDelegate: InternalChatDelegate {
        struct Metadata: Codable {
            var CorrelationId: String
            var type: String
        }

        struct Conversation: Codable {
            var id: String
        }

        struct Sender: Codable {
            var id: String
        }

        struct Member: Codable {
            var id: String
            var state: String
            var role: String
        }

        struct EventBody: Codable {
            var id: String?
            var conversation: Conversation?
            var sender: Sender?
            var member: Member?
            var body: String?
            var bodyType: String?
            var message: String?
            var timestamp: String?
        }

        struct Event: Codable {
            var topicName: String
            var version: String?
            var eventBody: EventBody
            var metadata: Metadata?
        }

        var members: Dictionary<String, Member> = Dictionary() {
            didSet {
                checkIfQueuedAndSignalDelegate()
                checkIfAgentJoinedAndSignalDelegate()
                checkIfCustomerGotDisconnectedAndSignalDelegate(oldValue)
            }
        }

        var parent: GenesysCloudGuestChatTicketProvider?

        init() { }

        private func checkIfQueuedAndSignalDelegate() {

            guard members.filter({ element in
                element.value.state.caseInsensitiveCompare("connected") == .orderedSame &&
                    element.value.role.caseInsensitiveCompare("acd") == .orderedSame
            }).count > 0 else {
                return
            }

            parent!.delegateOnQueued()
        }

        private func checkIfAgentJoinedAndSignalDelegate() {
            guard members.filter({ element in
                element.value.state.caseInsensitiveCompare("connected") == .orderedSame &&
                    element.value.role.caseInsensitiveCompare("agent") == .orderedSame
            }).count > 0 else {
                return
            }

            let notice = parent?.delegateOnAgentConnected()

            if (notice != nil) {
                sendNotice(notice!)
            }
        }

        private func checkIfCustomerGotDisconnectedAndSignalDelegate(_ oldValue: Dictionary<String, Member>) {
            let memberId = parent!.memberId()

            guard oldValue[memberId] != nil else {
                return
            }

            guard members[memberId] != nil else {
                // member removed
                customerDisconnected()
                return
            }

            guard oldValue[memberId]!.state.caseInsensitiveCompare("disconnected") != .orderedSame else {
                return
            }

            guard members[memberId]!.state.caseInsensitiveCompare("disconnected") == .orderedSame else {
                return
            }
            // customer state switched to DISCONNECTED
            customerDisconnected()
        }

        func customerDisconnected() {
            parent!.delegateOnError(CustomerDisconnectedError(conversationId: parent!.id(), memberId: parent!.memberId()))
        }

        func sendNotice(_ notice: String) {
            let conversationId = parent!.id()
            let customerId = parent!.memberId()
            let pcEnvironment = Options.get("pcEnvironment") ?? "mypurecloud.com"
            var request = URLRequest(url: URL(string: "https://api.\(pcEnvironment)/api/v2/webchat/guest/conversations/\(conversationId)/members/\(customerId)/messages")!)
            request.httpMethod = "POST"

            let noticeBody = EventBody(body: notice, bodyType: "notice")
            request.httpBody = try? encoder.encode(noticeBody)
            request.addValue("Bearer \(parent!.jwt())", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let session = URLSession.shared

            let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                guard error == nil else {
                    os_log(.error, "chat notice failed: \(error?.localizedDescription ?? "unknown")")
                    return
                }

                guard response != nil else {
                    os_log(.error, "chat notice failed: nil response")
                    return
                }

                guard response is HTTPURLResponse else {
                    os_log(.error, "chat notice failed: no http response")
                    return
                }

                let httpResponse = response as! HTTPURLResponse

                guard httpResponse.statusCode == 200 else {
                    os_log(.error, "chat notice failed: status code \(httpResponse.statusCode)")
                    return
                }
            })
            task.resume()
        }

        func onDataReceived(_ data: Data) {
            os_log("data received \(data)")
        }

        func onMessageReceived(_ message: String) {
            let event = try? decoder.decode(Event.self, from: message.data(using: .utf8)!)

            os_log("processing \(message)")

            switch event?.metadata?.type {
            case "message":
                handleMessage(event!.eventBody)
                break
            case "member-change":
                handleMemberChange(event!.eventBody)
                break
            case .none:
                break
            case .some(_):
                break
            }
        }

        func handleMessage(_ eventBody: EventBody) {
            let conversationId = eventBody.conversation!.id
            guard conversationId == parent?.id() else {
                os_log("ignoring message of unknown conversation \(conversationId)")
                return
            }

            switch eventBody.bodyType {
            case "member-join":
                handleMemberJoin(eventBody)
                break
            case "member-leave":
                handleMemberLeave(eventBody)
                break
            case "notice":
                handleNoticeMessage(eventBody)
                break
            case .none:
                break
            case .some(_):
                break
            }
        }

        func onConnected(_ chat: GenesysCloudGuestChatTicketProvider) {
            self.parent = chat
            parent!.delegate?.onSocketConnected()
        }

        func onError(_ error: Error) {
            parent!.delegate?.onError(error)
        }

        private func handleNoticeMessage(_ eventBody: EventBody) {
            let conversationId = eventBody.conversation!.id

            guard conversationId == parent?.id() else {
                os_log("ignoring message of unknown conversation \(conversationId)")
                return
            }

            let memberRole = members[eventBody.sender!.id]!.role
            guard memberRole.caseInsensitiveCompare("agent") == .orderedSame else {
                return
            }

            let message = eventBody.body!
            guard message.range(of: #"^https?:\/\/\w+(\.\w+)*(:[0-9]+)?(\/.*)?$"#, options: .regularExpression) != nil else {
                return
            }

            let url = URL(string: message)

            let ticket = url?.path.suffix(7)

            os_log("ticket received \(ticket ?? "nil")")
            if ticket != nil {
                parent?.delegateOnTicket("\(ticket!)")
            }
        }

        private func handleMemberJoin(_ eventBody: EventBody) {
            let conversationId = eventBody.conversation!.id

            guard conversationId == parent?.id() else {
                os_log("ignoring message of unknown conversation \(conversationId)")
                return
            }

            let id = eventBody.sender!.id
            let state = "unknown"
            let role = "unknown"
            let member = Member(id: id, state: state, role: role)

            members.updateValue(member, forKey: id)

            hydrateMember(id)
        }

        private func hydrateMember(_ id: String) {
            let conversationId = parent!.id()
            let pcEnvironment = Options.get("pcEnvironment") ?? "mypurecloud.com"

            var request = URLRequest(url: URL(string: "https://api.\(pcEnvironment)/api/v2/webchat/guest/conversations/\(conversationId)/members/\(id)")!)
            request.httpMethod = "GET"
            request.addValue("Bearer \(parent!.jwt())", forHTTPHeaderField: "Authorization")

            let session = URLSession.shared

            let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                let httpResponse = response as! HTTPURLResponse

                guard httpResponse.statusCode == 200 else {
                    os_log("member info request failed: status code \(httpResponse.statusCode)")
                    return
                }

                do {
                    let member = try decoder.decode(Member.self, from: data!)
                    self.members.updateValue(member, forKey: id)
                } catch {
                    os_log("member info response json parse error \(error.localizedDescription)")
                }
            })
            task.resume()
        }

        private func handleMemberLeave(_ eventBody: EventBody) {
            let conversationId = eventBody.conversation!.id

            guard conversationId == parent?.id() else {
                os_log("ignoring message of unknown conversation \(conversationId)")
                return
            }

            let id = eventBody.sender!.id

            members.removeValue(forKey: id)
        }

        private func handleMemberChange(_ eventBody: EventBody) {
            let conversationId = eventBody.conversation!.id

            guard conversationId == parent?.id() else {
                os_log("ignoring message of unknown conversation \(conversationId)")
                return
            }

            let id = eventBody.member!.id
            let state = eventBody.member!.state

            members[id]?.state = state
        }
    }
}
