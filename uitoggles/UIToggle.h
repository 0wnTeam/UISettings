@interface UISettingsToggleController : NSObject {
}
+(UISettingsToggleController*)sharedController;
-(UILabel*)createLabelForButton:(UIButton*)button text:(NSString*)title;
-(UIButton*)createToggleWithAction:(SEL)action title:(NSString*)title target:(id)target;
-(void)createToggleWithTitle:(NSString*)title andImage:(NSString*)path andSelector:(SEL)selector toTarget:(id)target;
@end

