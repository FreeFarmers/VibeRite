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
            return "Fix grammar and spelling while preserving the original meaning and tone."
        case .improveWriting:
            return "Improve this writing for clarity, flow, and readability."
        case .professionalTone:
            return "Rewrite this text in a professional and polished tone."
        case .friendlyTone:
            return "Rewrite this text in a warm and friendly tone."
        case .makeShorter:
            return "Shorten this text while preserving the key meaning."
        case .rewriteClearly:
            return "Rewrite this text with maximum clarity and readability."
        case .summarize:
            return "Summarize this text in a concise and clear way."
        }
    }

    /// System message sent to Ollama — keeps small models from adding conversational wrappers.
    var systemPrompt: String {
        """
        You are a silent text editor. Output only the final edited text.
        Never write introductions, labels, or meta phrases such as "Here is the rewritten text".
        Never use markdown fences or quotation marks around the result.
        """
    }

    func buildPrompt(action: WritingAction, userText: String) -> String {
        """
        Task: \(instruction(for: action))

        Output rules (mandatory):
        - Output ONLY the rewritten message body.
        - No preamble, postamble, titles, or explanations.
        - No phrases like "Here is", "Here's", "Rewritten text", or "Sure".
        - Start directly with the first word of the rewritten text.

        Message to rewrite:
        \(userText)
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

        // Remove wrapping quotes if the model wrapped the entire output once.
        if result.hasPrefix("\""), result.hasSuffix("\""), result.count > 2 {
            result = String(result.dropFirst().dropLast())
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
