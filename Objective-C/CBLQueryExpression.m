//
//  CBLQueryExpression.m
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 3/8/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

#import "CBLQueryExpression.h"
#import "CBLXQuery+Internal.h"

@implementation CBLQueryExpression


+ (CBLQueryExpression*) property: (NSString*)property {
    return [[CBLQueryTypeExpression alloc] initWithKeypath: property];
}


+ (CBLQueryExpression*) group: (CBLQueryExpression*)expression, ... {
    NSMutableArray* exps = [NSMutableArray array];
    va_list args;
    va_start(args, expression);
    id arg = nil;
    while((arg=va_arg(args, id))) {
        [exps addObject: arg];
    }
    va_end(args);
    return [[CBLQueryCompoundPredicate alloc] initWithType: NSAndPredicateType
                                             subpredicates: exps];
}


// Unary operators.
+ (CBLQueryExpression*) negated: (id)expression {
    return [[CBLQueryCompoundPredicate alloc] initWithType: NSNotPredicateType
                                             subpredicates: @[expression]];
}


+ (CBLQueryExpression*) not: (id)expression {
    return [self negated: expression];
}


- (CBLQueryExpression*) operatorExpressionWithType: (NSPredicateOperatorType)type
                                 againstExpression: (id)expression
{
    Assert([self isKindOfClass: [CBLQueryTypeExpression class]], @"The operation is not supported.");
    CBLQueryTypeExpression* lhs = (CBLQueryTypeExpression*)self;
    CBLQueryTypeExpression* rhs = $castIf(CBLQueryTypeExpression, expression);
    if (!rhs) {
        Assert(![expression isKindOfClass: [CBLQueryExpression class]], @"Invalid expression value");
        rhs = [[CBLQueryTypeExpression alloc] initWithConstantValue: expression];
    }
    return [[CBLQueryComparisonPredicate alloc] initWithLeftExpression: lhs
                                                       rightExpression: rhs
                                                                  type: type];
}


// Binary operators.
- (CBLQueryExpression*) concat: (id)expression {
    Assert(NO, @"Unsupported operation");
}


- (CBLQueryExpression*) multiply: (id)expression {
    return [[CBLQueryTypeExpression alloc] initWithFunction: @"multiply:by:"
                                                  arguments: @[self, expression]];
}


- (CBLQueryExpression*) divide: (id)expression {
    return [[CBLQueryTypeExpression alloc] initWithFunction: @"divide:by:"
                                                  arguments: @[self, expression]];
}


- (CBLQueryExpression*) modulo: (id)expression {
    return [[CBLQueryTypeExpression alloc] initWithFunction: @"modulus:by:"
                                                  arguments: @[self, expression]];
}


- (CBLQueryExpression*) add: (id)expression {
    return [[CBLQueryTypeExpression alloc] initWithFunction: @"add:to:"
                                                  arguments: @[self, expression]];
}


- (CBLQueryExpression*) subtract: (id)expression {
    return [[CBLQueryTypeExpression alloc] initWithFunction: @"from:subtract:"
                                                  arguments: @[self, expression]];
}


- (CBLQueryExpression*) lessThan: (id)expression {
    return [self operatorExpressionWithType: NSLessThanPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) notLessThan: (id)expression {
    return [self operatorExpressionWithType: NSGreaterThanOrEqualToPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) lessThanOrEqualTo: (id)expression {
    return [self operatorExpressionWithType: NSLessThanOrEqualToPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) notLessThanOrEqualTo: (id)expression {
    return [self operatorExpressionWithType: NSGreaterThanPredicateOperatorType
                          againstExpression: expression];

}


- (CBLQueryExpression*) greaterThan: (id)expression {
    return [self operatorExpressionWithType: NSGreaterThanPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) notGreaterThan: (id)expression {
    return [self operatorExpressionWithType: NSLessThanOrEqualToPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) greaterThanOrEqualTo: (id)expression {
    return [self operatorExpressionWithType: NSGreaterThanOrEqualToPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) notGreaterThanOrEqualTo: (id)expression {
    return [self operatorExpressionWithType: NSLessThanPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) equalTo: (id)expression {
    return [self operatorExpressionWithType: NSEqualToPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) notEqualTo: (id)expression {
    return [self operatorExpressionWithType: NSNotEqualToPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) and: (id)expression {
    return [[CBLQueryCompoundPredicate alloc] initWithType: NSAndPredicateType
                                             subpredicates: @[self, expression]];
}


- (CBLQueryExpression*) or: (id)expression {
    return [[CBLQueryCompoundPredicate alloc] initWithType: NSOrPredicateType
                                             subpredicates: @[self, expression]];
}


- (CBLQueryExpression*) like: (id)expression {
    return [self operatorExpressionWithType: NSLikePredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) notLike: (id)expression {
    return [[self class] negated: [self like: expression]];
}


- (CBLQueryExpression*) regex: (id)expression {
    return [[CBLQueryTypeExpression alloc] initWithFunction: @"REGEXP_LIKE"
                                                  arguments: @[self, expression]];
}


- (CBLQueryExpression*) notRegex: (id)expression {
    return [[self class] negated: [self notRegex: expression]];
}


- (CBLQueryExpression*) match: (id)expression {
    return [self operatorExpressionWithType: NSMatchesPredicateOperatorType
                          againstExpression: expression];
}


- (CBLQueryExpression*) notMatch: (id)expression {
    return [[self class] negated: [self match: expression]];
}


- (CBLQueryExpression*) isNull {
    return [self equalTo: nil];
}


- (CBLQueryExpression*) notNull {
    return [self notEqualTo: nil];
}


- (CBLQueryExpression*) is: (id)expression {
    return [self equalTo: expression];
}


- (CBLQueryExpression*) isNot: (id)expression {
    return [self notEqualTo: expression];
}


- (CBLQueryExpression*) between: (id)expression1 and: (id)expression2 {
    Assert([self isKindOfClass: [CBLQueryTypeExpression class]], @"The operation is not supported.");
    CBLQueryTypeExpression* lhs = (CBLQueryTypeExpression*)self;
    
    CBLQueryTypeExpression* exp1 = $castIf(CBLQueryTypeExpression, expression1);
    if (!exp1) {
        Assert(![exp1 isKindOfClass: [CBLQueryExpression class]], @"Invalid expression value");
        exp1 = [[CBLQueryTypeExpression alloc] initWithConstantValue: expression1];
    }
    CBLQueryTypeExpression* exp2 = $castIf(CBLQueryTypeExpression, expression2);
    if (!exp2) {
        Assert(![exp1 isKindOfClass: [CBLQueryExpression class]], @"Invalid expression value");
        exp2 = [[CBLQueryTypeExpression alloc] initWithConstantValue: expression2];
    }
    CBLQueryTypeExpression* rhs = [[CBLQueryTypeExpression alloc] initWithAggregateExpressions: @[exp1, exp2]];
    
    return [[CBLQueryComparisonPredicate alloc] initWithLeftExpression: lhs
                                                       rightExpression: rhs
                                                                  type: NSBetweenPredicateOperatorType];
}


- (CBLQueryExpression*) notBetween: (id)exp1 and: (id)exp2 {
    return [[self class] negated: [self between: exp1 and: exp2]];
}


- (CBLQueryExpression*) inExpressions: (NSArray*)expressions {
    Assert([self isKindOfClass: [CBLQueryTypeExpression class]], @"The operation is not supported.");
    CBLQueryTypeExpression* lhs = (CBLQueryTypeExpression*)self;
    CBLQueryTypeExpression* rhs = [[CBLQueryTypeExpression alloc] initWithAggregateExpressions: expressions];
    return [[CBLQueryComparisonPredicate alloc] initWithLeftExpression: lhs
                                                       rightExpression: rhs
                                                                  type: NSInPredicateOperatorType];
}


- (CBLQueryExpression*) notInExpressions: (NSArray*)expressions {
    return [[self class] negated: [self notInExpressions: expressions]];
}


@end


/////


@implementation CBLQueryComparisonPredicate

@synthesize leftExpression=_leftExpression, rightExpression=_rightExpression;
@synthesize predicateOperatorType=_predicateOperatorType;

- (instancetype) initWithLeftExpression: (CBLQueryTypeExpression*)lhs
                        rightExpression: (CBLQueryTypeExpression*)rhs
                                   type: (NSPredicateOperatorType)type
{
    self = [super init];
    if (self) {
        _leftExpression = lhs;
        _rightExpression = rhs;
        _predicateOperatorType = type;
    }
    return self;
}

- (NSPredicate*) asNSPredicate {
    return [NSComparisonPredicate predicateWithLeftExpression: [self.leftExpression asNSExpression]
                                              rightExpression: [self.rightExpression asNSExpression]
                                                     modifier: NSDirectPredicateModifier
                                                         type: self.predicateOperatorType
                                                      options: 0];
}

@end


/////


@implementation CBLQueryCompoundPredicate

@synthesize compoundPredicateType=_compoundPredicateType, subpredicates=_subpredicates;

- (instancetype) initWithType: (NSCompoundPredicateType)type subpredicates: (NSArray*)subs {
    self = [super init];
    if (self) {
        _compoundPredicateType = type;
        _subpredicates = [subs copy];
    }
    return self;
}

- (NSPredicate*) asNSPredicate {
    NSMutableArray* subs = [NSMutableArray array];
    for (id s in self.subpredicates) {
        Assert([s conformsToProtocol: @protocol(CBLNSPredicateCoding)]);
        [subs addObject: [s asNSPredicate]];
    }
    
    NSPredicate* p = nil;
    switch (self.compoundPredicateType) {
        case NSAndPredicateType:
            p = [NSCompoundPredicate andPredicateWithSubpredicates: subs];
            break;
        case NSOrPredicateType:
            p = [NSCompoundPredicate orPredicateWithSubpredicates: subs];
            break;
        default:
            Assert(subs.count > 0);
            p = [NSCompoundPredicate notPredicateWithSubpredicate: subs[0]];
            break;
    }
    return p;
}

@end


/////


@implementation CBLQueryTypeExpression

@synthesize expressionType=_expressionType;
@synthesize constantValue=_constantValue, keyPath=_keyPath;
@synthesize function=_function, arguments=_arguments;
@synthesize subexpressions=_subexpressions;

- (instancetype) initWithType: (NSExpressionType)type {
    self = [super init];
    if (self) {
        _expressionType = type;
    }
    return self;
}

- (instancetype) initWithConstantValue: (id)value {
    self = [self initWithType: NSConstantValueExpressionType];
    if (self) {
        _constantValue = value;
    }
    return self;
}

- (instancetype) initWithKeypath: (NSString*)keyPath {
    self = [self initWithType: NSKeyPathExpressionType];
    if (self) {
        _keyPath = [keyPath copy];
    }
    return self;
}

- (instancetype) initWithFunction: (NSString*)function arguments: (NSArray*)arguments {
    self = [self initWithType: NSFunctionExpressionType];
    if (self) {
        _function = [function copy];
        _arguments = [arguments copy];
    }
    return self;
}

- (instancetype) initWithAggregateExpressions: (NSArray*)subexpressions {
    self = [self initWithType: NSAggregateExpressionType];
    if (self) {
        _subexpressions = [subexpressions copy];
    }
    return self;
}

- (NSExpression*) asNSExpression {
    NSExpression* exp = nil;
    switch (self.expressionType) {
        case NSConstantValueExpressionType:
            exp = [NSExpression expressionForConstantValue: self.constantValue];
            break;
        case NSKeyPathExpressionType:
            Assert(self.keyPath);
            exp = [NSExpression expressionForKeyPath: self.keyPath];
            break;
        case NSFunctionExpressionType: {
            NSArray* args = [self toNSExpressionArray: self.arguments];
            exp = [NSExpression expressionForFunction: self.function arguments: args];
            break;
        }
        case NSAggregateExpressionType: {
            NSArray* subs = [self toNSExpressionArray: self.subexpressions];
            exp = [NSExpression expressionForAggregate: subs];
            break;
        }
        default:
            Assert(false, @"Unsupported expression type: %d", self.expressionType);
            break;
    }
    return exp;
}

- (NSArray*) toNSExpressionArray: (NSArray*)expressions {
    NSMutableArray* array = [NSMutableArray array];
    for (id exp in expressions) {
        if ([exp respondsToSelector:@selector(asNSExpression)])
            [array addObject: [exp performSelector: @selector(asNSExpression)]];
        else {
            Assert(![exp isKindOfClass: [CBLQueryExpression class]], @"Invalid expression value");
            [array addObject: [NSExpression expressionForConstantValue: exp]];
        }
    }
    return array;
}

@end
