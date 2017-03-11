//
//  XQueryTest.m
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 3/13/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

#import "CBLTestCase.h"
#import "CBLXQuery.h"
#import "CBLQuerySelect.h"
#import "CBLQueryDataSource.h"
#import "CBLQueryOrderBy.h"

@interface XQueryTest : CBLTestCase

@end

@implementation XQueryTest

- (uint64_t) verifyQuery: (CBLXQuery*)q test: (void (^)(uint64_t n, CBLQueryRow *row))block {
    NSError* error;
    NSEnumerator* e = [q run: &error];
    Assert(e, @"Query failed: %@", error);
    uint64_t n = 0;
    for (CBLQueryRow *row in e) {
        //Log(@"Row: docID='%@', sequence=%llu", row.documentID, row.sequence);
        block(++n, row);
    }
    return n;
}


- (NSArray*)loadNumbers:(NSInteger)num {
    NSMutableArray* numbers = [NSMutableArray array];
    NSError *batchError;
    BOOL ok = [self.db inBatch: &batchError do: ^{
        for (NSInteger i = 1; i <= num; i++) {
            NSError* error;
            NSString* docId= [NSString stringWithFormat: @"doc%ld", (long)i];
            CBLDocument* doc = [self.db documentWithID: docId];
            doc[@"number1"] = @(i);
            doc[@"number2"] = @(num-i);
            bool saved = [doc save: &error];
            Assert(saved, @"Couldn't save document: %@", error);
            [numbers addObject: doc.properties];
        }
    }];
    Assert(ok, @"Error when inserting documents: %@", batchError);
    return numbers;
}


- (void) runTestWithNumbers: (NSArray*)numbers cases: (NSArray*)cases {
    for (NSArray* c in cases) {
        CBLXQuery* q = [CBLXQuery select: [CBLQuerySelect all]
                                    from: [CBLQueryDatabase database: self.db]
                                   where: c[0]];
        NSPredicate* p = [NSPredicate predicateWithFormat: c[1]];
        NSMutableArray* result = [[numbers filteredArrayUsingPredicate: p] mutableCopy];
        [self verifyQuery: q test: ^(uint64_t n, CBLQueryRow *row) {
            id props = row.document.properties;
            Assert([result containsObject: props]);
            [result removeObject: props];
        }];
        
        NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>%@", c[1]);
        AssertEqual(result.count, 0u);
    }
}


- (void) test01_NoWhereQuery {
    [self loadJSONResource: @"names_100"];
    
    CBLXQuery* q = [CBLXQuery select: [CBLQuerySelect all]
                                from: [CBLQueryDatabase database: self.db]];
    Assert(q);
    uint64_t numRows = [self verifyQuery: q test:^(uint64_t n, CBLQueryRow *row) {
        NSString* expectedID = [NSString stringWithFormat: @"doc-%03llu", n];
        AssertEqualObjects(row.documentID, expectedID);
        AssertEqual(row.sequence, n);
        CBLDocument* doc = row.document;
        AssertEqualObjects(doc.documentID, expectedID);
        AssertEqual(doc.sequence, n);
    }];
    AssertEqual(numRows, 100llu);
}


- (void) test02_WhereComparison {
    CBLQueryExpression* n1 = [CBLQueryExpression property: @"number1"];
    NSArray* cases = @[
        @[[n1 lessThan: @(3)], @"number1 < 3"],
        @[[n1 notLessThan: @(3)], @"number1 >= 3"],
        @[[n1 lessThanOrEqualTo: @(3)], @"number1 <= 3"],
        @[[n1 notLessThanOrEqualTo: @(3)], @"number1 > 3"],
        @[[n1 greaterThan: @(6)], @"number1 > 6"],
        @[[n1 notGreaterThan: @(6)], @"number1 <= 6"],
        @[[n1 greaterThanOrEqualTo: @(6)], @"number1 >= 6"],
        @[[n1 notGreaterThanOrEqualTo: @(6)], @"number1 < 6"],
        @[[n1 equalTo: @(7)], @"number1 == 7"],
        @[[n1 notEqualTo: @(7)], @"number1 != 7"]
    ];
    NSArray* numbers = [self loadNumbers: 10];
    [self runTestWithNumbers: numbers cases: cases];
}


- (void) test03_WhereWithArithmetic {
    CBLQueryExpression* n1 = [CBLQueryExpression property: @"number1"];
    CBLQueryExpression* n2 = [CBLQueryExpression property: @"number2"];
    NSArray* cases = @[
        @[[[n1 multiply: @(2)] greaterThan: @(8)], @"(number1 * 2) > 8"],
        @[[[n1 divide: @(2)] greaterThan: @(3)], @"(number1 / 2) > 3"],
        @[[[n1 modulo: @(2)] equalTo: @(0)], @"modulus:by:(number1, 2) == 0"],
        @[[[n1 add: @(5)] greaterThan: @(10)], @"(number1 + 5) > 10"],
        @[[[n1 subtract: @(5)] greaterThan: @(0)], @"(number1 - 5) > 0"],
        @[[[n1 multiply: n2] greaterThan: @(10)], @"(number1 * number2) > 10"],
        @[[[n2 divide: n1] greaterThan: @(3)], @"(number2 / number1) > 3"],
        @[[[n2 modulo: n1] equalTo: @(0)], @"modulus:by:(number2, number1) == 0"],
        @[[[n1 add: n2] equalTo: @(10)], @"(number1 + number2) == 10"],
        @[[[n1 subtract: n2] greaterThan: @(0)], @"(number1 - number2) > 0"]
    ];
    NSArray* numbers = [self loadNumbers: 10];
    [self runTestWithNumbers: numbers cases: cases];
}


- (void) test04_WhereAndOr {
    CBLQueryExpression* n1 = [CBLQueryExpression property: @"number1"];
    CBLQueryExpression* n2 = [CBLQueryExpression property: @"number2"];
    NSArray* cases = @[
        @[[[n1 greaterThan: @(3)] and: [n2 greaterThan: @(3)]], @"number1 > 3 AND number2 > 3"],
        @[[[n1 lessThan: @(3)] or: [n2 lessThan: @(3)]], @"number1 < 3 OR number2 < 3"]
    ];
    NSArray* numbers = [self loadNumbers: 10];
    [self runTestWithNumbers: numbers cases: cases];
}


- (void) failingTest05_WhereCheckNull {
    NSError* error;
    CBLDocument* doc1 = [self.db document];
    doc1[@"number"] = @(1);
    Assert([doc1 save: &error], @"Error when creating a document: %@", error);
    
    CBLDocument* doc2 = [self.db document];
    doc2[@"string"] = @"string";
    Assert([doc2 save: &error], @"Error when creating a document: %@", error);
    
    CBLXQuery* q = [CBLXQuery select: [CBLQuerySelect all]
                                from: [CBLQueryDatabase database: self.db]
                               where: [[CBLQueryExpression property: @"number"] notNull]];
    Assert(q);
    uint64_t numRows = [self verifyQuery: q test: ^(uint64_t n, CBLQueryRow *row) {
        CBLDocument* doc = row.document;
        AssertEqualObjects(doc.documentID, doc1.documentID);
        AssertEqualObjects(doc[@"number"], @(1));
    }];
    AssertEqual(numRows, 1u);
    
    q = [CBLXQuery select: [CBLQuerySelect all]
                     from: [CBLQueryDatabase database: self.db]
                    where: [[CBLQueryExpression property: @"number"] isNull]];
    Assert(q);
    numRows = [self verifyQuery: q test: ^(uint64_t n, CBLQueryRow *row) {
        CBLDocument* doc = row.document;
        AssertEqualObjects(doc.documentID, doc1.documentID);
        AssertEqualObjects(doc[@"string"], @"string");
    }];
    AssertEqual(numRows, 1u);
}


- (void) test06_WhereIs {
    
}


- (void) test07_WhereBetween {
    
}


- (void) test08_WhereIn {
    
}


- (void) test09_SelectGroup {
    
}

- (void) test10_SelectDistinct {
    
}

@end
