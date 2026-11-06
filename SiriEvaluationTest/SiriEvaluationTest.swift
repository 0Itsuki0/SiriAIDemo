//
//  SiriEvaluationTest.swift
//  SiriEvaluationTest
//
//  Created by Itsuki on 2026/11/05.
//

import SiriEvaluations
import Testing

// A sample custom evaluator to get a metrics for whether Siri called exactly 1 intent per turn
extension Metric { static let customMetrics = Metric("One Intent Per Turn") }

struct CustomEvaluator: EvaluatorProtocol {
    func metrics(subject: SiriScenarioSubject, input: SiriScenario) async throws
        -> [Metric]
    {
        let oneIntentTurns = subject.siriTranscript.turns.count(where: {
            $0.intentInvocations.count == 1
        })
        return [
            Metric.customMetrics.scoring(
                Double(oneIntentTurns) / Double(subject.siriTranscript.turns.count)
            )
        ]
    }
}

struct SiriAIDemoSiriEvaluation: Evaluation {
    // The title of the evaluation's report in Xcode.
    let name: String

    // The loader that holds the scenarios you write.
    let dataset: SiriScenarioLoader

    // The method that runs one scenario through Siri.
    func subject(from sample: SiriScenario) async throws -> SiriScenarioSubject
    {
        return try await SiriService.run(scenario: sample)
    }

    // The evaluators that grade what Siri does.
    var evaluators: Evaluators {
        SiriExpectationEvaluator()
        CustomEvaluator()
    }

    // The method that decides which metrics the evaluation reports.
    func aggregateMetrics(using aggregator: inout MetricsAggregator) {
        Self.computeSiriMetrics(into: &aggregator)
    }
}

// App Intent: https://developer.apple.com/documentation/appintentstesting/testing-your-app-intents-code
@Suite("SiriAIDemo - SiriEvaluation", .serialized)
struct SiriAIDemoSiriEvaluationTests {
    static let appDefinitions = IntentDefinitions(
        bundleIdentifier: "itsuki.enjoy.SiriAIDemo"
    )

    /// App entities
    static let GroceryEntity = appDefinitions.entities["GroceryEntity"]
    static let AppRouteEnum = appDefinitions.enums["AppRoute"]

    /// app intents
    static let AddGroceryIntent = appDefinitions.intents["AddGrocery"]
    static let OpenCheckoutIntent = appDefinitions.intents["OpenCheckout"]

    /// app skills
    static let MakePurchaseSkill = appDefinitions.skills["make-purchase"]

    // MARK: - test intents
    static let addGroceryScenario = SiriScenario {
        UserTurn("In SiriAIDemo, add 3 apples to my shopping cart") {
            Finds {
                GroceryEntity.expectIdentifier("apple")
            }
            Calls {
                AddGroceryIntent
                    /// expected intent parameters
                    /// Pass `isNil` to expect a parameter to be absent.
                    /// To leave a value unchecked, pass `nil` or leave out its label instead.
                    ///
                    /// The framework checks each parameter as the caller passed it,
                    /// *before* any entity query runs.
                    .expect(
                        /// An entity parameter accepts an entity definition or an AppEntityIdentifierExpectation,
                        /// but **not** an AppEntityExpectation.
                        item: GroceryEntity.expectIdentifier("apple"),
                        /// match with primitive(string/nil):
                        /// https://developer.apple.com/documentation/appintentstesting/primitiveexpectation
                        /// match with predicate:
                        /// https://developer.apple.com/documentation/appintentstesting/predicateexpectation
                        quantity: .matches(#Predicate<Int> { $0 == 3 })
                    )
                    /// expected intent results
                    /// Pass isNil to expect no result.
                    /// or some specific value, for example: if we return the added grocery, `.result(GroceryEntity.expectIdentifier("apple"))`
                    .result(.isNil)
            }

            /// to disallow specific intents:
            /// Calls(.disallowed) { Intent1; Intent2... }
        }
    }

    static let addGroceryEvaluation = SiriAIDemoSiriEvaluation(
        name: "SiriAIDemo - add grocery",
        dataset: SiriScenarioLoader { addGroceryScenario }
    )

    @Test(
        "Siri add the grocery with the correct item and quantity",
        .evaluates(addGroceryEvaluation)
    )
    func addGroceryTest() {
        let result = EvaluationContext.current.result
        #expect(result.aggregateValue(.mean(of: .intentsAllPass)) == 1.0)
        #expect(result.aggregateValue(.mean(of: .foundEntitiesAllPass)) == 1.0)
    }

    // MARK: - test skills
    static let makePurchaseScenario = SiriScenario {
        UserTurn("I want to buy 3 apples in SiriAIDemo.") {
            Loads(.required) { MakePurchaseSkill }
        }
    }

    static let makePurchaseEvaluation = SiriAIDemoSiriEvaluation(
        name: "SiriAIDemo - make purchase skill",
        dataset: SiriScenarioLoader { makePurchaseScenario }
    )

    @Test("Siri loads make purchase skill", .evaluates(makePurchaseEvaluation))
    func loadMakePurchaseSkillTest() {
        let result = EvaluationContext.current.result
        #expect(result.aggregateValue(.mean(of: .skillsLoadedAllPass)) == 1.0)
    }
}
