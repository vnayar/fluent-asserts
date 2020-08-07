module fluentasserts.core.operations.approximately;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;
import fluentasserts.core.array;
import fluentasserts.core.serializers;
import fluentasserts.core.operations.contain;

import fluentasserts.core.lifecycle;

import std.algorithm;
import std.array;
import std.conv;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] approximately(ref Evaluation evaluation) @trusted nothrow {
  double maxRelDiff;
  real[] testData;
  real[] expectedPieces;

  try {
    testData = evaluation.currentValue.strValue.parseList.cleanString.map!(a => a.to!real).array;
    expectedPieces = evaluation.expectedValue.strValue.parseList.cleanString.map!(a => a.to!real).array;
    maxRelDiff = evaluation.expectedValue.meta["1"].to!double;
  } catch(Exception e) {
    return [ new MessageResult("Can not perform the assert.") ];
  }

  auto comparison = ListComparison!real(testData, expectedPieces, maxRelDiff);

  auto missing = comparison.missing;
  auto extra = comparison.extra;
  auto common = comparison.common;

  IResult[] results = [];

  bool allEqual = testData.length == common.length;

  string strExpected;
  string strMissing;

  if(maxRelDiff == 0) {
    strExpected = evaluation.expectedValue.strValue;
    try strMissing = missing.length == 0 ? "" : missing.to!string;
    catch(Exception) {}
  } else try {
    strMissing = "[" ~ missing.map!(a => a.to!string ~ "±" ~ maxRelDiff.to!string).join(", ") ~ "]";
    strExpected = "[" ~ expectedPieces.map!(a => a.to!string ~ "±" ~ maxRelDiff.to!string).join(", ") ~ "]";
  } catch(Exception) {}

  if(!evaluation.isNegated) {
    if(!allEqual) {
      try results ~= new ExpectedActualResult(strExpected, evaluation.expectedValue.strValue);
      catch(Exception) {}

      try results ~= new ExtraMissingResult(extra.length == 0 ? "" : extra.to!string, strMissing);
      catch(Exception) {}
    }
  } else {
    if(allEqual) {
      try results ~= new ExpectedActualResult("not " ~ strExpected, evaluation.expectedValue.strValue);
      catch(Exception) {}
    }
  }

  return results;
}
