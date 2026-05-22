//
//  VibeRiteTests.swift
//  VibeRiteTests
//
//  Created by Ahsan Minhas on 22/05/2026.
//

import Testing
@testable import VibeRite

struct VibeRiteTests {

    @Test func promptTemplateIncludesInstruction() {
        let service = PromptTemplateService()
        let prompt = service.buildPrompt(action: .fixGrammar, userText: "hello world")
        #expect(prompt.contains("Fix grammar and spelling"))
        #expect(prompt.contains("hello world"))
    }

    @Test func writingActionServiceMessagesAreUnique() {
        let messages = Set(WritingAction.allCases.map(\.serviceMessage))
        #expect(messages.count == WritingAction.allCases.count)
    }

    @Test func sanitizeModelOutputStripsPreamble() {
        let service = PromptTemplateService()
        let raw = """
        Here is the rewritten text:

        Hi Alma, I wanted to share our Eid events.
        """
        let cleaned = service.sanitizeModelOutput(raw)
        #expect(!cleaned.lowercased().contains("here is the rewritten"))
        #expect(cleaned.hasPrefix("Hi Alma"))
    }

    @Test func ollamaModelsHaveStableRawValues() {
        #expect(OllamaModel.llama32_3b.rawValue == "llama3.2:3b")
        #expect(OllamaModel.llama3.rawValue == "llama3")
        #expect(OllamaModel.mistral.rawValue == "mistral")
        #expect(OllamaModel.gemma.rawValue == "gemma")
        #expect(OllamaModel.default == .llama32_3b)
    }
}
