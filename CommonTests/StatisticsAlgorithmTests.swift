//
//  StatisticsAlgorithmTests.swift
//  Essentia
//
//  Created by Jason Cardwell on 11/22/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import XCTest
@testable import Essentia
import AVFoundation
import Accelerate

// Declare custom operators since they cannot be exported from `Essentia`.
infix operator >>
infix operator >!
postfix operator >>|
postfix operator >>>

class StatisticsAlgorithmTests: XCTestCase {

  /// Tests the functionality of the PoolAggregator algorithm. Values taken from
  /// `test_poolaggregator.py`.
  func testPoolAggregator() {

    /*
     Test real-valued results.
     */

    let pool1: Pool = ["foo": [1, 1, 2, 3, 5, 8, 13, 21, 34]]
    let aggregator1 = PoolAggregatorAlgorithm([
      .defaultStats: ["mean", "min", "max", "median", "var", "stdev",
                      "dmean", "dvar", "dmean2", "dvar2"]
      ])
    aggregator1[poolInput: .input] = pool1
    aggregator1.compute()
    let result1 = aggregator1[poolOutput: .output]

    XCTAssertEqual(result1[real: "foo.mean"], 9.77777777778)
    XCTAssertEqual(result1[real: "foo.median"], 5)
    XCTAssertEqual(result1[real: "foo.min"], 1)
    XCTAssertEqual(result1[real: "foo.max"], 34)
    XCTAssertEqual(result1[real: "foo.var"], 112.172839506, deviation: 1e-5)
    XCTAssertEqual(result1[real: "foo.stdev"], 10.591167995362929, deviation: 1e-5)
    XCTAssertEqual(result1[real: "foo.dmean"], 4.125)
    XCTAssertEqual(result1[real: "foo.dvar"], 17.109375)
    XCTAssertEqual(result1[real: "foo.dmean2"], 1.85714285714)
    XCTAssertEqual(result1[real: "foo.dvar2"], 2.40816326531, accuracy: 1e-6)

    /*
     Test that registered exceptions are skipped.
     */

    let pool2: Pool = ["foo.bar": [1.1, 2.2, 3.3], "bar.foo": [-6.9, 6.9]]
    let aggregator2 = PoolAggregatorAlgorithm([
      .defaultStats: ["mean", "var", "min", "max"],
      .exceptions: ["foo.bar": ["min"]]
      ])
    aggregator2[poolInput: .input] = pool2
    aggregator2.compute()
    let result2 = aggregator2[poolOutput: .output]

    XCTAssertEqual(result2.descriptorNames.sorted(),
                   ["bar.foo.max", "bar.foo.mean", "bar.foo.min", "bar.foo.var", "foo.bar.min"])

    XCTAssertEqual(result2[real: "foo.bar.min"], 1.1)
    XCTAssertEqual(result2[real: "bar.foo.min"], -6.9)
    XCTAssertEqual(result2[real: "bar.foo.max"], 6.9)
    XCTAssertEqual(result2[real: "bar.foo.mean"], 0)
    XCTAssertEqual(result2[real: "bar.foo.var"], 47.61)

    /*
     Test string aggregation.
     */

    let pool3: Pool = ["foo": ["foo", "bar"]]
    let aggregator3 = PoolAggregatorAlgorithm()
    aggregator3[poolInput: .input] = pool3
    aggregator3.compute()
    let result3 = aggregator3[poolOutput: .output]

    XCTAssertEqual(result3[stringVec: "foo"], ["foo", "bar"])
    XCTAssertEqual(result3.descriptorNames, ["foo"])

    /*
     Test real vector aggregation.
     */

    let pool4: Pool = ["foo": [[1.1, 2.2, 3.3], [4.4, 5.5, 6.6], [7.7, 8.8, 9.9]]]
    let aggregator4 = PoolAggregatorAlgorithm([
      .defaultStats: ["mean", "min", "max", "median", "var", "stdev",
                      "dmean", "dvar", "dmean2", "dvar2"]
      ])
    aggregator4[poolInput: .input] = pool4
    aggregator4.compute()
    let result4 = aggregator4[poolOutput: .output]

    XCTAssertEqual(result4[realVec: "foo.mean"], [4.4, 5.5, 6.6])
    XCTAssertEqual(result4[realVec: "foo.median"], [4.4, 5.5, 6.6])
    XCTAssertEqual(result4[realVec: "foo.min"], [1.1, 2.2, 3.3])
    XCTAssertEqual(result4[realVec: "foo.max"], [7.7, 8.8, 9.9])
    XCTAssertEqual(result4[realVec: "foo.var"], [7.26, 7.26, 7.26], deviation: 1e-5)
    XCTAssertEqual(result4[realVec: "foo.stdev"], [2.6944387, 2.6944387, 2.6944387], accuracy: 1e-6)
    XCTAssertEqual(result4[realVec: "foo.dmean"], [3.3, 3.3, 3.3], deviation: 1e-5)
    XCTAssertEqual(result4[realVec: "foo.dvar"], [0, 0, 0], accuracy: 1e-7)
    XCTAssertEqual(result4[realVec: "foo.dmean2"], [0, 0, 0], accuracy: 1e-6)
    XCTAssertEqual(result4[realVec: "foo.dvar2"], [0, 0, 0], accuracy: 1e-6)

    /*
     Test median for an even number frames.
     */

    pool4.add(.realVec([10, 10, 10]), for: "foo")
    let aggregator5 = PoolAggregatorAlgorithm([
      .defaultStats: ["mean", "min", "max", "median", "var", "stdev",
                      "dmean", "dvar", "dmean2", "dvar2"]
      ])
    aggregator5[poolInput: .input] = pool4
    aggregator5.compute()
    let result5 = aggregator5[poolOutput: .output]

    XCTAssertEqual(result5[realVec: "foo.median"], [6.05, 7.15, 8.25])

    /*
     Test cov and icov computations.
     */

    let pool6: Pool = ["foo": [[32.3, 43.21, 4.3],
                               [44.0, 5.12, 3.21],
                               [45.12, 415.0, 89.4],
                               [112.15, 45.0, 1.0023]]]
    let aggregator6 = PoolAggregatorAlgorithm([.defaultStats: ["cov", "icov"]])
    aggregator6[poolInput: .input] = pool6
    aggregator6.compute()
    let result6 = aggregator6[poolOutput: .output]

    XCTAssertEqual(result6[realVecVec: "foo.cov"],
                   [[1317.99694824, -1430.0489502, -430.359405518],
                    [-1430.0489502, 37181.1601563, 8301.80175781],
                    [-430.359405518, 8301.80175781, 1875.15136719]],
                   deviation: 1e-4)

    XCTAssertEqual(result6[realVecVec: "foo.icov"],
                   [[0.00144919625018, -0.00161361286882, 0.0074764424935],
                    [-0.00161361729261, 0.00413948250934, -0.018696943298],
                    [0.00747651979327, -0.0186969414353, 0.0850256085396]],
                   accuracy: 1e-4)

    /*
     Test string vector aggregation.
     */

    let pool7: Pool = ["foo": [["qt", "is", "sweet"],
                               ["peanut", "butter", "jelly", "time"],
                               ["yo no", "hablo", "espanol"]]]
    let aggregator7 = PoolAggregatorAlgorithm()
    aggregator7[poolInput: .input] = pool7
    aggregator7.compute()
    let result7 = aggregator7[poolOutput: .output]

    XCTAssertEqual(result7.descriptorNames, ["foo"])
    XCTAssertEqual(result7[stringVecVec: "foo"],
                   [["qt", "is", "sweet"],
                    ["peanut", "butter", "jelly", "time"],
                    ["yo no", "hablo", "espanol"]])

    /*
     Test that no calculations are performed when the lengths of the vectors are unequal.
     */

    let pool8: Pool = ["foo": [[548.4, 489.44, 45787.0], [45.1, 78.0]]]
    let aggregator8 = PoolAggregatorAlgorithm()
    aggregator8[poolInput: .input] = pool8
    aggregator8.compute()
    let result8 = aggregator8[poolOutput: .output]

    XCTAssert(result8.descriptorNames.isEmpty)

    /*
    Test that no calculations are performed when an empty array is present.
     */

    let pool9: Pool = ["foo": [[ 4.489, 22.0, 7.0], [], [89.153, 0.134, 10.1544564]]]
    let aggregator9 = PoolAggregatorAlgorithm()
    aggregator9[poolInput: .input] = pool9
    aggregator9.compute()
    let result9 = aggregator9[poolOutput: .output]

    XCTAssert(result9.descriptorNames.isEmpty)

    /*
     Test copying of statistics.
     */

    let pool10: Pool = [
      "foo": [3, 6, 3, 2, 39],
      "bar.ff.wfew.f.gr.g.re.gr.e.gregreg.re.gr.eg.re": [[324, 5, 54], [543, 234, 57]]
    ]
    let aggregator10 = PoolAggregatorAlgorithm([.defaultStats: ["copy"]])
    aggregator10[poolInput: .input] = pool10
    aggregator10.compute()
    let result10 = aggregator10[poolOutput: .output]

    XCTAssertEqual(result10[realVec: "foo"], [3, 6, 3, 2, 39])
    XCTAssertEqual(result10[realVecVec: "bar.ff.wfew.f.gr.g.re.gr.e.gregreg.re.gr.eg.re"],
                   [[324, 5, 54], [543, 234, 57]])
    XCTAssertEqual(result10.descriptorNames.sorted(),
                   ["bar.ff.wfew.f.gr.g.re.gr.e.gregreg.re.gr.eg.re", "foo"])

    /*
     Test 'value' inclusion.
     */

    let pool11: Pool = ["foo": [1, 2, 3, 4, 5]]
    let aggregator11 = PoolAggregatorAlgorithm([.defaultStats: ["max", "value"]])
    aggregator11[poolInput: .input] = pool11
    aggregator11.compute()
    let result11 = aggregator11[poolOutput: .output]

    XCTAssert(result11.contains(name: "foo.max"))
    XCTAssert(result11.contains(name: "foo.value"))
    XCTAssertEqual(result11[real: "foo.max"], 5)
    XCTAssertEqual(result11[realVec: "foo.value"], [1, 2, 3, 4, 5])

    /*
     Test 'last' inclusion.
     */

    let pool12: Pool = ["foo": [1, 2, 3, 4, 5],
                        "foo_vector": [[1, 2, 3], [4, 5, 6], [7, 8, 9]]]
    let aggregator12 = PoolAggregatorAlgorithm([.defaultStats: ["last"]])
    aggregator12[poolInput: .input] = pool12
    aggregator12.compute()
    let result12 = aggregator12[poolOutput: .output]

    XCTAssert(result12.contains(name: "foo"))
    XCTAssert(result12.contains(name: "foo_vector"))

    XCTAssertEqual(result12[real: "foo"], 5)
    XCTAssertEqual(result12[realVec: "foo_vector"], [7, 8, 9])

    /*
     Test real matrix calculations.
     */

    let pool13: Pool = ["foo.bar": [[[0, 1], [2, 3]], [[1, 2], [3, 4]], [[2, 3], [4, 5]]]]
    let aggregator13 = PoolAggregatorAlgorithm([
      .defaultStats: ["mean", "min", "max", "var", "dmean", "dvar", "dmean2", "dvar2"]
      ])
    aggregator13[poolInput: .input] = pool13
    aggregator13.compute()
    let result13 = aggregator13[poolOutput: .output]

    XCTAssertEqual(result13[realVecVec: "foo.bar.min"], [[0, 1], [2, 3]])
    XCTAssertEqual(result13[realVecVec: "foo.bar.max"], [[2, 3], [4, 5]])
    XCTAssertEqual(result13[realVecVec: "foo.bar.mean"], [[1, 2], [3, 4]])
    XCTAssertEqual(result13[realVecVec: "foo.bar.var"],
                   [[0.6666666667, 0.6666666667], [0.6666666667, 0.6666666667]],
                   accuracy: 1e-7)
    XCTAssertEqual(result13[realVecVec: "foo.bar.dmean"], [[1, 1], [1, 1]])
    XCTAssertEqual(result13[realVecVec: "foo.bar.dvar"], [[0, 0], [0, 0]])
    XCTAssertEqual(result13[realVecVec: "foo.bar.dmean2"], [[0, 0], [0, 0]])
    XCTAssertEqual(result13[realVecVec: "foo.bar.dvar2"], [[0, 0], [0, 0]])

  }

  /// Tests the functionality of the PowerMean algorithm. Values taken from `test_powermean.py`.
  func testPowerMean() {

    /*
     Test with all-zero input.
     */

    let alg1 = PowerMeanAlgorithm()
    alg1[realVecInput: .array] = [0.0] * 10
    alg1.compute()

    XCTAssertEqual(alg1[realOutput: .powerMean], 0)

    /*
     Test with a single input.
     */

    let alg2 = PowerMeanAlgorithm()
    alg2[realVecInput: .array] = [100]
    alg2.compute()

    XCTAssertEqual(alg2[realOutput: .powerMean], 100, accuracy: 1e-7)

    let alg3 = PowerMeanAlgorithm([.power: 0])
    alg3[realVecInput: .array] = [100]
    alg3.compute()

    XCTAssertEqual(alg3[realOutput: .powerMean], 100, accuracy: 1e-5)

    let alg4 = PowerMeanAlgorithm([.power: -2])
    alg4[realVecInput: .array] = [100]
    alg4.compute()

    XCTAssertEqual(alg4[realOutput: .powerMean], 100, accuracy: 1e-7)

    let alg5 = PowerMeanAlgorithm([.power: 6])
    alg5[realVecInput: .array] = [100]
    alg5.compute()

    XCTAssertEqual(alg5[realOutput: .powerMean], 100, accuracy: 1e-4)

    /*
     Test with multi-value array.
     */

    let alg6 = PowerMeanAlgorithm()
    alg6[realVecInput: .array] = [5, 8, 4, 9, 1]
    alg6.compute()

    XCTAssertEqual(alg6[realOutput: .powerMean], 5.4, accuracy: 1e-7)

    let alg7 = PowerMeanAlgorithm([.power: 0])
    alg7[realVecInput: .array] = [5, 8, 4, 9, 1]
    alg7.compute()

    XCTAssertEqual(alg7[realOutput: .powerMean], 4.28225474, accuracy: 1e-7)

    let alg8 = PowerMeanAlgorithm([.power: -3])
    alg8[realVecInput: .array] = [5, 8, 4, 9, 1]
    alg8.compute()

    XCTAssertEqual(alg8[realOutput: .powerMean], 1.69488507, accuracy: 1e-4)

    let alg9 = PowerMeanAlgorithm([.power: 4])
    alg9[realVecInput: .array] = [5, 8, 4, 9, 1]
    alg9.compute()

    XCTAssertEqual(alg9[realOutput: .powerMean], 6.93105815, accuracy: 1e-4)


    /*
     Test with rational numbers.
     */

    let alg10 = PowerMeanAlgorithm()
    alg10[realVecInput: .array] = [3.1459, 0.4444, 0.00002]
    alg10.compute()

    XCTAssertEqual(alg10[realOutput: .powerMean], 1.19677333, accuracy: 1e-4)

    let alg11 = PowerMeanAlgorithm([.power: 0])
    alg11[realVecInput: .array] = [3.1459, 0.4444, 0.00002]
    alg11.compute()

    XCTAssertEqual(alg11[realOutput: .powerMean], 0.0303516976, accuracy: 1e-7)

    let alg12 = PowerMeanAlgorithm([.power: -5.1])
    alg12[realVecInput: .array] = [3.1459, 0.4444, 0.00002]
    alg12.compute()

    XCTAssertEqual(alg12[realOutput: .powerMean], 2.48075104e-5, accuracy: 1e-7)

    let alg13 = PowerMeanAlgorithm([.power: 2.3])
    alg13[realVecInput: .array] = [3.1459, 0.4444, 0.00002]
    alg13.compute()

    XCTAssertEqual(alg13[realOutput: .powerMean], 1.96057772, accuracy: 1e-7)

  }

  /// Tests the functionality of the InstantPower algorithm. Values taken from
  /// `test_instantpower.py`.
  func testInstantPower() {

    /*
     Test with all-zero input.
     */

    let alg1 = InstantPowerAlgorithm()
    alg1[realVecInput: .array] = [0.0] * 1000
    alg1.compute()

    XCTAssertEqual(alg1[realOutput: .power], 0)

    /*
     Test with a single value.
     */

    let alg2 = InstantPowerAlgorithm()
    alg2[realVecInput: .array] = [23]
    alg2.compute()

    XCTAssertEqual(alg2[realOutput: .power], 529)

    /*
     Test for regression.
     */

    let alg3 = InstantPowerAlgorithm()
    alg3[realVecInput: .array] = [0, 1, 2, 3]
    alg3.compute()

    XCTAssertEqual(alg3[realOutput: .power], 3.5, accuracy: 1e-7)


  }

}
