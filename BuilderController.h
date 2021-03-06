//
//  BuilderController.h
//  BetaBuilder
//
//  Created by Hunter Hillegas on 8/7/10.
//  Copyright 2010 Hunter Hillegas. All rights reserved.
//

/* 
 iOS BetaBuilder - a tool for simpler iOS betas
 Version 1.5, January 2011
 
 Condition of use and distribution:
 
 This software is provided 'as-is', without any express or implied
 warranty.  In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
 2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 */

#import <Cocoa/Cocoa.h>


@interface BuilderController : NSObject {
	NSTextField *bundleIdentifierField;
	NSTextField *bundleVersionField;
	NSTextField *bundleNameField;
	NSTextField *webserverDirectoryField;
	NSTextField *archiveIPAFilenameField;
	
	NSButton *generateFilesButton;
	
	NSString *mobileProvisionFilePath;
}

@property (nonatomic, retain) IBOutlet NSTextField *bundleIdentifierField;
@property (nonatomic, retain) IBOutlet NSTextField *bundleVersionField;
@property (nonatomic, retain) IBOutlet NSTextField *bundleNameField;
@property (nonatomic, retain) IBOutlet NSTextField *webserverDirectoryField;
@property (nonatomic, retain) IBOutlet NSTextField *archiveIPAFilenameField;

@property (nonatomic, retain) IBOutlet NSButton *generateFilesButton;

@property (nonatomic, copy) NSString *mobileProvisionFilePath;

- (IBAction)specifyIPAFile:(id)sender;
- (IBAction)generateFiles:(id)sender;

- (void)setupFromIPAFile:(NSString *)ipaFilename;

- (void)populateFieldsFromHistoryForBundleID:(NSString *)bundleID;
- (void)storeFieldsInHistoryForBundleID:(NSString *)bundleID;

@end
