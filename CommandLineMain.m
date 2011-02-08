//
//  CommandLineMain.m
//  BetaBuilder
//
//  Created by Scott Gruby on 2/7/11.
//  Copyright 2011 Gruby Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSFileManager+DirectoryLocations.h"
#import "ZipArchive.h"

NSString *htmlTemplate(void)
{
	return @"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"
	"<html xmlns=\"http://www.w3.org/1999/xhtml\">"
	"<head>"
	"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />"
	"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0\">"
	"<title>[BETA_NAME] [BETA_VERSION] - Beta Release</title>"
	"<style type=\"text/css\">"
	"body {background:#fff;margin:0;padding:0;font-family:arial,helvetica,sans-serif;text-align:center;padding:10px;color:#333;font-size:16px;}"
	"#container {width:300px;margin:0 auto;}"
	"h1 {margin:0;padding:0;font-size:14px;}"
	"p {font-size:13px;}"
	".link {background:#ecf5ff;border-top:1px solid #fff;border:1px solid #dfebf8;margin-top:.5em;padding:.3em;}"
	".link a {text-decoration:none;font-size:15px;display:block;color:#069;}"
	".last_updated {font-size: x-small;text-align: right;font-style: italic;}"
	".created_with {font-size: x-small;text-align: center;}"
	"</style>"
	"</head>"
	"<body>"
	""
	"<div id=\"container\">"
	""
	"<h1>iOS 4.0+ Users:</h1>"
	""
	"<div class=\"link\"><a href=\"itms-services://?action=download-manifest&url=[BETA_PLIST]\">Tap Here to Install<br />[BETA_NAME] [BETA_VERSION]<br />Directly On Your Device</a></div>"
	""
	"<p><strong>Link didn't work?</strong><br />"
	"Make sure you're visiting this page on your device, not your computer.</p>"
	""
	"<p class=\"last_updated\">Last Updated: [BETA_DATE]</p>"
	""
    "<p class=\"created_with\"><a href='http://www.hanchorllc.com/category/ios-betabuilder/'>Created With iOS BetaBuilder</a></p>"
	"</div>"
	""
	"</body>"
	"</html>";
}

void generateFiles(NSString *sourceIPA, NSString *destinationPath, NSString *webserverPath)
{
	if (sourceIPA == nil || destinationPath == nil || webserverPath == nil)
	{
		return;
	}

	NSString *mobileProvisionFilePath = nil;
	NSString *bundleVersion = nil;
	NSString *bundleIdentifier = nil;
	NSString *bundleName = nil;
	//Attempt to pull values
	NSError *fileCopyError;
	NSError *fileDeleteError;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *ipaSourceURL = [NSURL fileURLWithPath:sourceIPA];
	NSURL *ipaDestinationURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [sourceIPA lastPathComponent]]];
	[fileManager removeItemAtURL:ipaDestinationURL error:&fileDeleteError];
	BOOL copiedIPAFile = [fileManager copyItemAtURL:ipaSourceURL toURL:ipaDestinationURL error:&fileCopyError];
	
    if (!copiedIPAFile)
	{
		NSLog(@"Error Copying IPA File: %@", fileCopyError);
	}
	else
	{
		//Remove Existing Trash in Temp Directory
		[fileManager removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"extracted_app"] error:nil];
		
		ZipArchive *za = [[ZipArchive alloc] init];
		if ([za UnzipOpenFile:[ipaDestinationURL path]]) {
			BOOL ret = [za UnzipFileTo:[NSTemporaryDirectory() stringByAppendingPathComponent:@"extracted_app"] overWrite:YES];
			if (NO == ret){} [za UnzipCloseFile];
		}
		[za release];
		
		//read the Info.plist file
		NSString *appDirectoryPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"extracted_app"] stringByAppendingPathComponent:@"Payload"];
		NSArray *payloadContents = [fileManager contentsOfDirectoryAtPath:appDirectoryPath error:nil];
		if ([payloadContents count] > 0) {
			NSString *plistPath = [[payloadContents objectAtIndex:0] stringByAppendingPathComponent:@"Info.plist"];
			NSDictionary *bundlePlistFile = [NSDictionary dictionaryWithContentsOfFile:[appDirectoryPath stringByAppendingPathComponent:plistPath]];
			
			if (bundlePlistFile) {
				bundleVersion = [[bundlePlistFile valueForKey:@"CFBundleVersion"] copy];
				[bundleVersion autorelease];
				bundleIdentifier = [[bundlePlistFile valueForKey:@"CFBundleIdentifier"] copy];
				[bundleIdentifier autorelease];
				bundleName = [[bundlePlistFile valueForKey:@"CFBundleDisplayName"] copy];
				[bundleName autorelease];
			}
			
			//set mobile provision file
			mobileProvisionFilePath = [appDirectoryPath stringByAppendingPathComponent:[[payloadContents objectAtIndex:0] stringByAppendingPathComponent:@"embedded.mobileprovision"]];
		}
	}

	
	
	//create plist
	NSString *encodedIpaFilename = [[sourceIPA lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //this isn't the most robust way to do this
	NSString *ipaURLString = [NSString stringWithFormat:@"%@/%@", webserverPath, encodedIpaFilename];
	NSDictionary *assetsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"software-package", @"kind", ipaURLString, @"url", nil];
	NSDictionary *metadataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:bundleIdentifier, @"bundle-identifier", bundleVersion, @"bundle-version", @"software", @"kind", bundleName, @"title", nil];
	NSDictionary *innerManifestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:assetsDictionary], @"assets", metadataDictionary, @"metadata", nil];
	NSDictionary *outerManifestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:innerManifestDictionary], @"items", nil];
	NSLog(@"Manifest Created");
	
	//create html file    
	NSString *htmlTemplateString = htmlTemplate();
	htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_NAME]" withString:bundleName];
    htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_VERSION]" withString:bundleVersion];
	htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_PLIST]" withString:[NSString stringWithFormat:@"%@/%@", webserverPath, @"manifest.plist"]];
	
    //add formatted date
    NSDateFormatter *shortDateFormatter = [[NSDateFormatter alloc] init];
    [shortDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [shortDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *formattedDateString = [shortDateFormatter stringFromDate:[NSDate date]];
    [shortDateFormatter release];
    htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_DATE]" withString:formattedDateString];
    
	
	[fileManager removeItemAtPath:destinationPath error:nil];
	[fileManager createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:nil];
	
	NSURL *saveDirectoryURL = [NSURL fileURLWithPath:destinationPath];
	
	//Write Files
	[outerManifestDictionary writeToURL:[saveDirectoryURL URLByAppendingPathComponent:@"manifest.plist"] atomically:YES];
	[htmlTemplateString writeToURL:[saveDirectoryURL URLByAppendingPathComponent:@"index.html"] atomically:YES encoding:NSASCIIStringEncoding error:nil];
	
	//Copy IPA
	fileCopyError = nil;
	ipaSourceURL = [NSURL fileURLWithPath:sourceIPA];
	ipaDestinationURL = [saveDirectoryURL URLByAppendingPathComponent:[sourceIPA lastPathComponent]];
	copiedIPAFile = [fileManager copyItemAtURL:ipaSourceURL toURL:ipaDestinationURL error:&fileCopyError];
	if (!copiedIPAFile) {
		NSLog(@"Error Copying IPA File: %@", fileCopyError);
		NSAlert *theAlert = [NSAlert alertWithError:fileCopyError];
		NSInteger button = [theAlert runModal];
		if (button != NSAlertFirstButtonReturn) {
			//user hit the rightmost button
		}
	}
	
#if 0
	//Create Archived Version for 3.0 Apps
	ZipArchive* zip = [[ZipArchive alloc] init];
	BOOL ret = [zip CreateZipFile2:[[saveDirectoryURL path] stringByAppendingPathComponent:@"beta_archive.zip"]];
	ret = [zip addFileToZip:sourceIPA newname:@"application.ipa"];
	ret = [zip addFileToZip:mobileProvisionFilePath newname:@"beta_provision.mobileprovision"];
	if(![zip CloseZipFile2]) {
		NSLog(@"Error Creating 3.x Zip File");
	}
	[zip release];
#endif
	NSLog(@"finished");
}



int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	if (argc != 4)
	{
		NSLog(@"Usage: %s <path to ipa> <destination path> <path on web server>", argv[0]);
	}
	else
	{
		NSString *ipaPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:argv[1] length:strlen(argv[1])];
		NSString *destPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:argv[2] length:strlen(argv[2])];
		NSString *webserverPath = [[NSString alloc] initWithUTF8String:argv[3]];
		
		generateFiles(ipaPath, destPath, webserverPath);
		[webserverPath autorelease];
	}

    [pool drain];
    return 0;
}
