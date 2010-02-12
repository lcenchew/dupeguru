/* 
Copyright 2010 Hardcoded Software (http://www.hardcoded.net)

This software is licensed under the "HS" License as described in the "LICENSE" file, 
which should be included with this package. The terms are also available at 
http://www.hardcoded.net/licenses/hs_license
*/

#import "ResultOutline.h"
#import "Dialogs.h"
#import "Utils.h"
#import "Consts.h"

@implementation ResultOutline
- (id)initWithPyParent:(id)aPyParent view:(HSOutlineView *)aOutlineView
{
    self = [super initWithPyClassName:@"PyResultOutline" pyParent:aPyParent view:aOutlineView];
    return self;
}

- (void)dealloc
{
    [_deltaColumns release];
    [super dealloc];
}

- (PyResultTree *)py
{
    return (PyResultTree *)py;
}

/* Public */
- (BOOL)powerMarkerMode
{
    return [[self py] powerMarkerMode];
}

- (void)setPowerMarkerMode:(BOOL)aPowerMarkerMode
{
    [[self py] setPowerMarkerMode:aPowerMarkerMode];
}

- (BOOL)deltaValuesMode
{
    return [[self py] deltaValuesMode];
}

- (void)setDeltaValuesMode:(BOOL)aDeltaValuesMode
{
    [[self py] setDeltaValuesMode:aDeltaValuesMode];
}

- (void)setDeltaColumns:(NSIndexSet *)aDeltaColumns
{
    [_deltaColumns release];
    _deltaColumns = [aDeltaColumns retain];
}

- (IBAction)markSelected:(id)sender
{
    [[self py] markSelected];
}

/* Datasource */
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)column byItem:(id)item
{
    NSIndexPath *path = item;
    NSString *identifier = [column identifier];
    if ([identifier isEqual:@"mark"]) {
        return b2n([self boolProperty:@"marked" valueAtPath:path]);
    }
    NSInteger columnId = [identifier integerValue];
    return [[self py] valueForPath:p2a(path) column:columnId];
}

- (void)outlineView:(NSOutlineView *)aOutlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (![[tableColumn identifier] isEqual:@"0"])
        return; //We only want to cover renames.
    NSIndexPath *path = item;
    NSString *oldName = [[self py] valueForPath:p2a(path) column:0];
    NSString *newName = object;
    if (![newName isEqual:oldName]) {
        BOOL renamed = [[self py] renameSelected:newName];
        if (!renamed) {
            [Dialogs showMessage:[NSString stringWithFormat:@"The name '%@' already exists.", newName]];
        }
    }
}

/* Delegate */
- (void)outlineView:(NSOutlineView *)aOutlineView didClickTableColumn:(NSTableColumn *)tableColumn
{
    if ([[outlineView sortDescriptors] count] < 1)
        return;
    NSSortDescriptor *sd = [[outlineView sortDescriptors] objectAtIndex:0];
    [[self py] sortBy:[[sd key] integerValue] ascending:[sd ascending]];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{ 
    NSIndexPath *path = item;
    BOOL isMarkable = [self boolProperty:@"markable" valueAtPath:path];
    if ([[tableColumn identifier] isEqual:@"mark"]) {
        [cell setEnabled:isMarkable];
    }
    if ([cell isKindOfClass:[NSTextFieldCell class]]) {
        // Determine if the text color will be blue due to directory being reference.
        NSTextFieldCell *textCell = cell;
        if (isMarkable) {
            [textCell setTextColor:[NSColor blackColor]];
        }
        else {
            [textCell setTextColor:[NSColor blueColor]];
        }
        if (([self deltaValuesMode]) && ([self powerMarkerMode] || ([path length] > 1))) {
            NSInteger i = [[tableColumn identifier] integerValue];
            if ([_deltaColumns containsIndex:i]) {
                [textCell setTextColor:[NSColor orangeColor]];
            }
        }
    }
}

/* Python --> Cocoa */
- (void)refresh /* Override */
{
    [super refresh];
    [outlineView expandItem:nil expandChildren:YES];
}

- (void)invalidateMarkings
{
    for (NSMutableDictionary *props in [itemData objectEnumerator]) {
        [props removeObjectForKey:@"marked"];
    }
    [outlineView setNeedsDisplay:YES];
}
@end