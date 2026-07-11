import Foundation

struct HalalClassifier {
    private struct Rule {
        let terms: [String]
        let title: String
        let verdict: Verdict
        let detail: String
    }

    private let rules: [Rule] = [
        Rule(
            terms: ["pork", "bacon", "ham", "lard", "porcine"],
            title: "Pork-derived ingredient",
            verdict: .haramConcern,
            detail: "The visible label includes a pork-related term. For halal-conscious shoppers, this is a clear avoid unless the wording is unrelated or has been misread."
        ),
        Rule(
            terms: ["wine", "beer", "rum", "brandy", "alcohol"],
            title: "Alcohol concern",
            verdict: .haramConcern,
            detail: "The visible label includes an alcohol-related term. Treat this as a halal concern unless the manufacturer clearly explains that it is not part of the final food."
        ),
        Rule(
            terms: ["gelatin", "gelatine"],
            title: "Gelatin",
            verdict: .sourceVaries,
            detail: "Gelatin can come from halal or non-halal animal sources. The label needs certification or a clear source."
        ),
        Rule(
            terms: ["e471", "mono- and diglycerides", "mono and diglycerides"],
            title: "E471",
            verdict: .sourceVaries,
            detail: "E471 can be plant-derived or animal-derived. Food labels often do not show the source."
        ),
        Rule(
            terms: ["rennet", "enzymes", "emulsifier", "flavourings", "flavorings"],
            title: "Source-varying ingredient",
            verdict: .sourceVaries,
            detail: "This ingredient can vary by source or manufacturing process. Look for halal certification or manufacturer detail."
        ),
        Rule(
            terms: ["e120", "cochineal", "carmine"],
            title: "E120 / carmine",
            verdict: .haramConcern,
            detail: "E120 is commonly derived from insects and is often avoided by halal-conscious shoppers."
        )
    ]

    func classify(_ input: String) -> ScanResult {
        let normalized = input.lowercased()
        let matches = rules.filter { rule in
            rule.terms.contains { normalized.contains($0) }
        }

        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ScanResult(
                input: "No ingredients entered",
                verdict: .unableToVerify,
                confidence: .unableToVerify,
                summary: "Add or scan an ingredient list so ClearHalal can check visible source concerns.",
                nextStep: "Type the ingredients from the packet or scan the label.",
                evidence: []
            )
        }

        let evidence = matches.map {
            EvidenceItem(title: $0.title, status: $0.verdict.rawValue, detail: $0.detail, verdict: $0.verdict)
        }

        if matches.contains(where: { $0.verdict == .haramConcern }) {
            return ScanResult(
                input: input,
                verdict: .haramConcern,
                confidence: .likely,
                summary: "The visible label includes an ingredient many halal-conscious shoppers should avoid.",
                nextStep: "Best choice: avoid this product unless the label has been misread or a trusted authority clearly confirms it is acceptable.",
                evidence: evidence,
                wasAvoided: true
            )
        }

        if matches.contains(where: { $0.verdict == .sourceVaries }) {
            return ScanResult(
                input: input,
                verdict: .sourceVaries,
                confidence: .uncertain,
                summary: "The visible label includes ingredients whose source is not clear enough to assume.",
                nextStep: "Do not treat this as confirmed halal from the label alone. Choose a certified alternative or verify the ingredient source.",
                evidence: evidence
            )
        }

        return ScanResult(
            input: input,
            verdict: .likelyHalal,
            confidence: .likely,
            summary: "No common source-varying or haram-concern ingredients were found in the visible text.",
            nextStep: "Still check for certification if the product is important for you or your family.",
            evidence: [
                EvidenceItem(
                    title: "Visible ingredients",
                    status: "No flagged terms found",
                    detail: "This is based only on the text you entered. Hidden processing aids or unclear sources may not appear on a label.",
                    verdict: .likelyHalal
                )
            ],
            isSaved: true
        )
    }
}
