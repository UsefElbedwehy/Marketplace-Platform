import Core
import DomainKit
import Observation

@Observable
@MainActor
final class MessageThreadViewModel {
    private(set) var messages: [Message] = []
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var errorMessage: String?
    private(set) var currentUserId: String?
    var draftBody = ""

    private let chatUseCase: ChatUseCase
    private let authUseCase: AuthUseCase
    private var pollTask: Task<Void, Never>?

    init(chatUseCase: ChatUseCase = Container.shared.chatUseCase(), authUseCase: AuthUseCase = Container.shared.authUseCase()) {
        self.chatUseCase = chatUseCase
        self.authUseCase = authUseCase
    }

    func load(conversationId: String) async {
        currentUserId = await authUseCase.currentSession()?.sub
        await refresh(conversationId: conversationId)
    }

    func refresh(conversationId: String) async {
        isLoading = messages.isEmpty
        errorMessage = nil
        defer { isLoading = false }
        do {
            messages = try await chatUseCase.fetchMessages(conversationId: conversationId)
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    func send(conversationId: String) async {
        let body = draftBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isSending else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            let message = try await chatUseCase.sendMessage(conversationId: conversationId, body: body)
            messages.append(message)
            draftBody = ""
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    func isFromCurrentUser(_ message: Message) -> Bool {
        message.senderId == currentUserId
    }

    /// A genuinely-live feel without real Realtime (see `ChatRoute`'s doc
    /// comment) — polls while the thread is on screen, stops when it isn't.
    /// `MessageThreadView` starts this in `.onAppear`/`.task` and cancels it
    /// in `.onDisappear`.
    func startPolling(conversationId: String, intervalSeconds: UInt64 = 3) {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
                guard !Task.isCancelled, let self else { return }
                await self.refresh(conversationId: conversationId)
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}
