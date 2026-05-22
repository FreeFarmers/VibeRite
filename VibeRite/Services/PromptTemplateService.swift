//
//  PromptTemplateService.swift
//  VibeRite
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import Foundation

/// Builds structured prompts for each writing action.
struct PromptTemplateService {
    func instruction(for action: WritingAction) -> String {
        switch action {
        case .fixGrammar:
            return """
            Fix grammar and spelling while preserving the original meaning and tone. \
            If the text is a question, return an improved version of that question — do not answer it.
            """
        case .improveWriting:
            return """
            Improve this writing for clarity, flow, and readability. \
            Do not answer questions or add new information — only rewrite the provided text.
            """
        case .professionalTone:
            return """
            Rewrite this text in a professional and polished tone. \
            Do not answer questions or add advice — only rewrite the provided text.
            """
        case .friendlyTone:
            return """
            Rewrite this text in a warm and friendly tone. \
            Do not answer questions or add advice — only rewrite the provided text.
            """
        case .makeShorter:
            return "Shorten this text while preserving the key meaning."
        case .rewriteClearly:
            return """
            Rewrite this text with maximum clarity and readability. \
            Do not answer questions or add new information — only rewrite the provided text.
            """
        case .summarize:
            return "Summarize this text in a concise and clear way."
        }
    }

    /// System message — keeps models from acting like chatbots.
    var systemPrompt: String {
        """
        You are a silent writing editor. You rewrite or edit text the user provides.

        Critical rules:
        - NEVER answer questions in the input. If the input is a question, return an improved version of that same question.
        - NEVER add facts, advice, recommendations, or sentences that were not in the original.
        - NEVER explain your changes or reply conversationally.
        - Output ONLY the final edited text.
        - Preserve intent and format (questions stay questions, lists stay lists).
        - No markdown fences or quotation marks around the result.
        """
    }

    func buildPrompt(action: WritingAction, userText: String) -> String {
        """
        You are editing text, not replying to it.

        Task: \(instruction(for: action))

        Output rules (mandatory):
        - Rewrite ONLY the text inside the <text> tags below.
        - Do not answer questions. Do not respond as a chatbot.
        - Keep roughly the same length unless the task says to shorten or summarize.
        - Output ONLY the rewritten text — no preamble, postamble, titles, or explanations.
        - No phrases like "Here is", "Here's", "Rewritten text", or "Sure".
        - Start directly with the first word of the rewritten text.

        <text>
        \(userText)
        </text>
        """
    }

    /// Strips common model preambles when the prompt alone is not enough.
    func sanitizeModelOutput(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let linePreamblePatterns = [
            #"(?i)^here(?:'s| is) the (?:rewritten|improved|edited|corrected|revised) text:\s*"#,
            #"(?i)^here(?:'s| is) (?:the )?(?:rewritten|improved|edited|corrected|revised) version:\s*"#,
            #"(?i)^(?:rewritten|improved|edited|corrected|revised) text:\s*"#,
            #"(?i)^sure[,!]?\s*"#,
            #"(?i)^certainly[,!]?\s*"#,
        ]

        for pattern in linePreamblePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)),
               let range = Range(match.range, in: result) {
                result = String(result[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if result.hasPrefix("\""), result.hasSuffix("\""), result.count > 2 {
            result = String(result.dropFirst().dropLast())
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
