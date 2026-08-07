import XCTest

final class LayoutConverterTests: XCTestCase {

    /// Skip tests that require both English and Russian layouts.
    private func requireEnRu() throws {
        let layouts = KeyboardLayoutMap.installedLayouts()
        guard layouts.count >= 2,
              layouts.contains(where: { $0.languages.contains("en") }),
              layouts.contains(where: { $0.languages.contains("ru") }) else {
            throw XCTSkip("EN+RU layouts required")
        }
    }

    // MARK: - EN → RU Conversion

    func testEnglishToRussian_ghbdtn() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("ghbdtn").converted
        XCTAssertEqual(result, "привет")
    }

    func testEnglishToRussian_ntcn() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("ntcn").converted
        XCTAssertEqual(result, "тест")
    }

    func testEnglishToRussian_cjkywt() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("cjkywt").converted
        XCTAssertEqual(result, "солнце")
    }

    func testEnglishToRussian_cnhjrf() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("cnhjrf").converted
        XCTAssertEqual(result, "строка")
    }

    func testEnglishToRussian_ghjdthrf() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("ghjdthrf").converted
        XCTAssertEqual(result, "проверка")
    }

    // MARK: - RU → EN Conversion

    func testRussianToEnglish_привет() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("привет").converted
        XCTAssertEqual(result, "ghbdtn")
    }

    func testRussianToEnglish_тест() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("тест").converted
        XCTAssertEqual(result, "ntcn")
    }

    func testRussianToEnglish_строка() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("строка").converted
        XCTAssertEqual(result, "cnhjrf")
    }

    // MARK: - Auto-Detection

    func testAutoDetection_latinText() throws {
        try requireEnRu()
        let direction = LayoutConverter.detectDirection("hello world")
        XCTAssertNotEqual(direction, .auto, "Direction should be resolved, not .auto")
    }

    func testAutoDetection_cyrillicText() throws {
        try requireEnRu()
        let direction = LayoutConverter.detectDirection("привет мир")
        XCTAssertNotEqual(direction, .auto, "Direction should be resolved, not .auto")
    }

    // MARK: - Mixed / Edge Cases

    func testMixedText_numbersPassThrough() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("ntcn123").converted
        XCTAssertEqual(result, "тест123")
    }

    func testMixedText_spacesPassThrough() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("ghbdtn vbh").converted
        XCTAssertEqual(result, "привет мир")
    }

    func testEmptyString() {
        let result = LayoutConverter.convertWithTarget("").converted
        XCTAssertEqual(result, "")
    }

    // MARK: - Uppercase

    func testUppercase_englishToRussian() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("Ghbdtn").converted
        XCTAssertEqual(result, "Привет")
    }

    func testUppercase_russianToEnglish() throws {
        try requireEnRu()
        let result = LayoutConverter.convertWithTarget("Привет").converted
        XCTAssertEqual(result, "Ghbdtn")
    }

    // MARK: - Roundtrip

    func testRoundtrip_englishToRussianAndBack() throws {
        try requireEnRu()
        let original = "ghbdtn"
        let russian = LayoutConverter.convertWithTarget(original).converted
        let backToEnglish = LayoutConverter.convertWithTarget(russian).converted
        XCTAssertEqual(backToEnglish, original)
    }

    // MARK: - Detection with multiple layouts

    func testDetection_uniqueCharsPreferred() throws {
        try requireEnRu()
        let direction = LayoutConverter.detectDirection("привет")
        XCTAssertEqual(direction, .layoutBToA)
    }

    func testDetection_latinTextDetectsAsLayoutA() throws {
        try requireEnRu()
        let direction = LayoutConverter.detectDirection("hello")
        XCTAssertEqual(direction, .layoutAToB)
    }

    // MARK: - Backward Compatibility

    func testBackwardCompat_lowercaseLetters() throws {
        try requireEnRu()
        let pairs: [(String, String)] = [
            ("q", "й"), ("w", "ц"), ("e", "у"), ("r", "к"), ("t", "е"),
            ("y", "н"), ("u", "г"), ("i", "ш"), ("o", "щ"), ("p", "з"),
            ("a", "ф"), ("s", "ы"), ("d", "в"), ("f", "а"), ("g", "п"),
            ("h", "р"), ("j", "о"), ("k", "л"), ("l", "д"),
            ("z", "я"), ("x", "ч"), ("c", "с"), ("v", "м"), ("b", "и"),
            ("n", "т"), ("m", "ь"),
        ]
        for (en, ru) in pairs {
            let result = LayoutConverter.convertWithTarget(en).converted
            XCTAssertEqual(result, ru, "'\(en)' should convert to '\(ru)'")
        }
    }

    func testBackwardCompat_uppercaseLetters() throws {
        try requireEnRu()
        let pairs: [(String, String)] = [
            ("Q", "Й"), ("W", "Ц"), ("E", "У"), ("R", "К"), ("T", "Е"),
            ("Y", "Н"), ("U", "Г"), ("I", "Ш"), ("O", "Щ"), ("P", "З"),
            ("A", "Ф"), ("S", "Ы"), ("D", "В"), ("F", "А"), ("G", "П"),
            ("H", "Р"), ("J", "О"), ("K", "Л"), ("L", "Д"),
            ("Z", "Я"), ("X", "Ч"), ("C", "С"), ("V", "М"), ("B", "И"),
            ("N", "Т"), ("M", "Ь"),
        ]
        for (en, ru) in pairs {
            let result = LayoutConverter.convertWithTarget("QQ\(en)").converted
            let expected = "ЙЙ\(ru)"
            XCTAssertEqual(result, expected, "'\(en)' uppercase should convert correctly")
        }
    }

    func testBackwardCompat_punctuation() throws {
        try requireEnRu()
        let pairs: [(String, String)] = [
            ("[", "х"), ("]", "ъ"),
            (";", "ж"), ("'", "э"),
            (",", "б"), (".", "ю"),
        ]
        for (en, ru) in pairs {
            let result = LayoutConverter.convertWithTarget("ghbdtn\(en)").converted
            XCTAssertEqual(result, "привет\(ru)", "'\(en)' should convert to '\(ru)'")
        }
    }

    func testBackwardCompat_shiftedPunctuation() throws {
        try requireEnRu()
        let pairs: [(String, String)] = [
            ("{", "Х"), ("}", "Ъ"),
            (":", "Ж"), ("\"", "Э"),
            ("<", "Б"), (">", "Ю"),
        ]
        for (en, ru) in pairs {
            let result = LayoutConverter.convertWithTarget("GHBDTN\(en)").converted
            XCTAssertEqual(result, "ПРИВЕТ\(ru)", "'\(en)' should convert to '\(ru)'")
        }
    }

    func testBackwardCompat_backtickTilde() throws {
        try requireEnRu()
        let result1 = LayoutConverter.convertWithTarget("ghbdtn`").converted
        XCTAssertTrue(result1.hasPrefix("привет"), "Letter portion should convert")
        XCTAssertNotEqual(result1, "ghbdtn`", "Backtick should be converted")

        let converted = LayoutConverter.convertWithTarget("ghbdtn`").converted
        let roundtrip = LayoutConverter.convertWithTarget(converted).converted
        XCTAssertEqual(roundtrip, "ghbdtn`", "Backtick roundtrip should work")
    }

    func testBackwardCompat_shiftedNumberRowConverts() throws {
        try requireEnRu()
        let symbols = ["@", "#", "$", "^", "&"]
        for sym in symbols {
            let result = LayoutConverter.convertWithTarget("ghbdtn\(sym)").converted
            let prefix = String(result.prefix(6))
            XCTAssertEqual(prefix, "привет", "Letter portion should convert with '\(sym)' appended")
        }
    }

    func testBackwardCompat_punctuationRoundtrip() throws {
        try requireEnRu()
        let testStrings = ["ghbdtn/", "ghbdtn|", "GHBDTN?"]
        for original in testStrings {
            let converted = LayoutConverter.convertWithTarget(original).converted
            let roundtrip = LayoutConverter.convertWithTarget(converted).converted
            XCTAssertEqual(roundtrip, original, "Roundtrip for '\(original)'")
        }
    }

    // MARK: - Stress + Performance
    //
    // Each block scales by a known unit ("ghbdtn " → "привет ", 7 chars) so
    // expected output is trivially derivable and we test both correctness and
    // throughput on the same fixture.

    /// One typical sentence (~50 chars).
    private static let oneSentenceReps = 7
    /// 2-3 sentences (~210 chars) — user-asked size.
    private static let twoThreeSentencesReps = 30
    /// ~10 sentences (~700 chars) — user-asked size.
    private static let tenSentencesReps = 100
    /// Stress (~5 KB) — well past any realistic single selection.
    private static let stressReps = 700

    private func makeFixture(reps: Int) -> (input: String, expected: String) {
        (String(repeating: "ghbdtn ", count: reps),
         String(repeating: "привет ", count: reps))
    }

    func testStress_LongTextProducesExpectedOutput() throws {
        try requireEnRu()
        let fixture = makeFixture(reps: Self.tenSentencesReps)
        let result = LayoutConverter.convertWithTarget(fixture.input).converted
        XCTAssertEqual(result, fixture.expected,
                       "Long-input conversion must match the per-token expected output")
    }

    func testStress_VeryLongInputDoesNotCorruptOutput() throws {
        try requireEnRu()
        let fixture = makeFixture(reps: Self.stressReps)
        let result = LayoutConverter.convertWithTarget(fixture.input).converted
        XCTAssertEqual(result.count, fixture.expected.count,
                       "Output length must match input character-for-character (no drops)")
        XCTAssertEqual(result, fixture.expected)
    }

    func testPerformance_ConvertOneSentence() throws {
        try requireEnRu()
        let input = makeFixture(reps: Self.oneSentenceReps).input
        measure { _ = LayoutConverter.convertWithTarget(input) }
    }

    func testPerformance_ConvertTwoThreeSentences() throws {
        try requireEnRu()
        let input = makeFixture(reps: Self.twoThreeSentencesReps).input
        measure { _ = LayoutConverter.convertWithTarget(input) }
    }

    func testPerformance_ConvertTenSentences() throws {
        try requireEnRu()
        let input = makeFixture(reps: Self.tenSentencesReps).input
        measure { _ = LayoutConverter.convertWithTarget(input) }
    }

    func testPerformance_ConvertStress() throws {
        try requireEnRu()
        let input = makeFixture(reps: Self.stressReps).input
        measure { _ = LayoutConverter.convertWithTarget(input) }
    }
}
