#import "Plugins.h"

@implementation Plugins
static NSMutableArray *plugins = nil;

+ (NSString *)makeJSON
{
    NSError *error;
    NSData  *data = [NSJSONSerialization dataWithJSONObject:plugins options:0 error:&error];

    if (error != nil)
    {
        return @"[]";
    }
    else
    {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
};

+ (void)init
{
    plugins = [[NSMutableArray alloc] init];

    NSString *path = [NSString pathWithComponents:@[ FileSystem.documents, @"Plugins" ]];
    [FileSystem createDirectory:path];

    NSArray *contents = [FileSystem readDirectory:path];

    for (NSString *folder in contents)
    {
        [Logger info:LOG_CATEGORY_PLUGINS format:@"Attempting to load %@...", folder];

        @try
        {
            NSString *dir = [NSString pathWithComponents:@[ path, folder ]];

            if (![FileSystem isDirectory:dir])
            {
                [Logger info:LOG_CATEGORY_PLUGINS
                      format:@"Skipping %@ as it is not a directory.", folder];
                continue;
            }

            NSString *data = [NSString pathWithComponents:@[ dir, @"manifest.json" ]];
            if (![FileSystem exists:data])
            {
                [Logger info:LOG_CATEGORY_PLUGINS
                      format:@"Skipping %@ as it is missing a manifest.", folder];
                continue;
            }

            __block NSMutableDictionary *manifest = nil;

            @try
            {
                id json = [Utilities parseJSON:[FileSystem readFile:data]];

                if ([json isKindOfClass:[NSDictionary class]])
                {
                    manifest = [json mutableCopy];
                }
                else
                {
                    [Logger info:LOG_CATEGORY_PLUGINS
                          format:@"Skipping %@ as its manifest is invalid.", folder];
                    continue;
                }
            }
            @catch (NSException *e)
            {
                [Logger error:LOG_CATEGORY_PLUGINS
                       format:@"Skipping %@ as its manifest failed to be parsed. (%@)", folder,
                              e.reason];
                continue;
            }

            NSString *entry = [NSString pathWithComponents:@[ dir, @"bundle.js" ]];
            if (![FileSystem exists:entry])
            {
                [Logger info:LOG_CATEGORY_PLUGINS
                      format:@"Skipping %@ as it is missing a bundle.", folder];
                continue;
            }

            NSData *bundle = [FileSystem readFile:entry];

            manifest[@"folder"] = folder;
            manifest[@"path"]   = dir;

            [plugins addObject:@{
                @"manifest" : manifest,
                @"bundle" : [[NSString alloc] initWithData:bundle encoding:NSUTF8StringEncoding]
            }];
        }
        @catch (NSException *e)
        {
            [Logger error:LOG_CATEGORY_PLUGINS format:@"Failed to load %@ (%@)", folder, e.reason];
        }
    }
};

@end