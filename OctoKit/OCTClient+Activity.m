//
//  OCTClient+Activity.m
//  OctoKit
//
//  Created by Piet Brauer on 14.02.14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "OCTClient+Activity.h"
#import "OCTClient+Private.h"
#import "OCTRepository.h"
#import "OCTBranch.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation OCTClient (Activity)

- (RACSignal *)hasUserStarredRepository:(OCTRepository *)repository {
	NSParameterAssert(repository != nil);
	if (!self.authenticated) return [RACSignal error:self.class.authenticationRequiredError];

	NSString *path = [NSString stringWithFormat:@"/user/starred/%@/%@", repository.ownerLogin, repository.name];
	NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:nil];
	return [[[self
		enqueueRequest:request resultClass:nil]
		reduceEach:^(NSHTTPURLResponse *response, id _) {
			return @(response.statusCode == 204);
		}]
		catch:^RACSignal *(NSError *error) {
			NSNumber *statusCode = error.userInfo[OCTClientErrorHTTPStatusCodeKey];
			if (statusCode.integerValue == 404) {
				return [RACSignal return:@NO];
			} else {
				return [RACSignal error:error];
			}
		}];
}

- (RACSignal *)starRepository:(OCTRepository *)repository {
	NSParameterAssert(repository != nil);
	if (!self.authenticated) return [RACSignal error:self.class.authenticationRequiredError];

	NSString *path = [NSString stringWithFormat:@"/user/starred/%@/%@", repository.ownerLogin, repository.name];
	NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:path parameters:nil];
	return [[self enqueueRequest:request resultClass:nil] ignoreValues];
}

- (RACSignal *)unstarRepository:(OCTRepository *)repository {
	NSParameterAssert(repository != nil);
	if (!self.authenticated) return [RACSignal error:self.class.authenticationRequiredError];

	NSString *path = [NSString stringWithFormat:@"/user/starred/%@/%@", repository.ownerLogin, repository.name];
	NSMutableURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:nil];
	return [[self enqueueRequest:request resultClass:nil] ignoreValues];
}

- (RACSignal *)createIssueWithTitle:(NSString*)title
							   body:(NSString*)body
						   assignee:(OCTUser*)assignee
						  milestone:(int64_t)milestone
							 labels:(NSArray*)labels
					   inRepository:(OCTRepository *)repository {
	NSParameterAssert(title != nil);
	NSParameterAssert(repository != nil);
	
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	parameters[@"title"] = title;
	if (body) {
		parameters[@"body"] = body;
	}
	if (assignee){
		parameters[@"assignee"] = assignee.name;
	}
	if (milestone!=0){
		parameters[@"milestone"] = @(milestone);
	}
	if (labels){
		parameters[@"labels"] = labels;
	}
	
	NSString *path = [NSString stringWithFormat:@"repos/%@/%@/issues", repository.ownerLogin, repository.name];
	NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters notMatchingEtag:nil];
	
	return [[self enqueueRequest:request resultClass:OCTIssue.class] oct_parsedResults];
}

@end
