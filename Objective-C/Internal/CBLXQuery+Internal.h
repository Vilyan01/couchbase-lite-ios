//
//  CBLXQuery+Internal.h
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 3/10/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

#import "CBLXQuery.h"
#import "CBLInternal.h"
#import "CBLQueryDataSource.h"
#import "CBLQuerySelect.h"
#import "CBLQueryExpression.h"
#import "CBLQueryOrderBy.h"

NS_ASSUME_NONNULL_BEGIN


/////

@interface CBLXQuery ()

@property (readonly, nonatomic) CBLQuerySelect* select;

@property (readonly, nonatomic) CBLQueryDataSource* from;

@property (nullable, nonatomic) CBLQueryExpression* where;

@property (nullable, nonatomic) CBLQueryOrderBy* orderBy;

/** Initializer. */
- (instancetype) initWithSelect: (CBLQuerySelect*)select
                           from: (CBLQueryDataSource*)from
                          where: (nullable CBLQueryExpression*)where
                        orderBy: (nullable CBLQueryOrderBy*)orderBy;

@end

/////

@interface CBLQueryDataSource ()

@property (readonly, nonatomic) id source;

- (instancetype) initWithDataSource: (id)source;

@end

/////

@interface CBLQueryDatabase ()

- (instancetype) initWithDatabase: (CBLDatabase*)database;

@end

/////

@interface CBLQuerySelect ()

@property (readonly, nullable, nonatomic) id select;

- (instancetype) initWithSelect: (nullable id)select;

@end


/////

@protocol CBLNSPredicateCoding <NSObject>
- (NSPredicate*) asNSPredicate;
@end

@class CBLQueryTypeExpression;

@interface CBLQueryComparisonPredicate: CBLQueryExpression <CBLNSPredicateCoding>

@property(readonly, nonatomic) CBLQueryTypeExpression *leftExpression;
@property(readonly, nonatomic) CBLQueryTypeExpression *rightExpression;
@property(readonly, nonatomic) NSPredicateOperatorType predicateOperatorType;

- (instancetype) initWithLeftExpression: (CBLQueryTypeExpression*)lhs
                        rightExpression: (CBLQueryTypeExpression*)rhs
                                   type: (NSPredicateOperatorType)type;

@end

/////

@interface CBLQueryCompoundPredicate: CBLQueryExpression <CBLNSPredicateCoding>

@property(readonly, nonatomic) NSCompoundPredicateType compoundPredicateType;
@property(readonly, copy, nonatomic) NSArray *subpredicates;

- (instancetype)initWithType: (NSCompoundPredicateType)type subpredicates: (NSArray*)subs;

@end

/////

@protocol CBLNSExpressionCoding <NSObject>
- (NSExpression*) asNSExpression;
@end

@interface CBLQueryTypeExpression: CBLQueryExpression <CBLNSExpressionCoding>

@property(readonly, nonatomic) NSExpressionType expressionType;
@property(nullable, readonly, nonatomic) id constantValue;
@property(nullable, readonly, copy, nonatomic) NSString* keyPath;
@property(nullable, readonly, copy, nonatomic) NSString* function;
@property(nullable, readonly, copy, nonatomic) NSArray*arguments;
@property(nullable, readonly, copy, nonatomic) NSArray*subexpressions;

- (instancetype) initWithConstantValue: (id)value;

- (instancetype) initWithKeypath: (NSString*)keyPath;

- (instancetype) initWithFunction: (NSString*)function arguments: (NSArray*)arguments;

- (instancetype) initWithAggregateExpressions: (NSArray*)subexpressions;

@end

/////

@interface CBLQueryOrderBy () <CBLJSONCoding>

@end


NS_ASSUME_NONNULL_END