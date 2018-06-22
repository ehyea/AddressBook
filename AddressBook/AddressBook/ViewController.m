//
//  ViewController.m
//  AddressBook
//
//  Created by apple on 2018/6/21.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "ViewController.h"
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#define Is_Up_Ios_9      ([[UIDevice currentDevice].systemVersion floatValue]) >= 9.0
@interface ViewController ()

-(IBAction)btnGetContacts:(id)sender;

@property (nonatomic, retain) IBOutlet UITextView *tContacts;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self requestAuthorization];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)btnGetContacts:(id)sender{
    [self fetchContact];
}

- (void)requestAuthorization{
    if(Is_Up_Ios_9){
        [self requestAuthorizationContacts];
    }else{
        [self requestAuthorizationAddressBook];
    }
}

- (void)fetchContact{
    NSArray *contacts = nil;
    if(Is_Up_Ios_9){
       contacts = [self fetchContactWithContact];
    }else{
       contacts = [self fetchContactWithAddressBook];
    }
    if(contacts){
        [self saveAddressBook:contacts];
    }
}
- (void)requestAuthorizationContacts{
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusNotDetermined) {
        CNContactStore * contactStore = [[CNContactStore alloc]init];
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * __nullable error) {
            if (!error) {
                if (granted) {//允许
                    NSLog(@"允许");
                }else{//拒绝
                    NSLog(@"拒绝");
                }
            }else{
                NSLog(@"错误!");
            }
        }];
    }
    else {
        
    }
}

- (NSMutableArray *)fetchContactWithContact {
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized) {////有权限访问
        CNContactStore * contactStore = [[CNContactStore alloc]init];

        NSMutableArray *contacts = [NSMutableArray array];
        // 3. 创建联系人信息的请求对象
        NSArray * keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
        
        // 4. 根据请求Key, 创建请求对象
        CNContactFetchRequest * request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
        
        // 5. 发送请求
        [contactStore enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            
            // 6.1 获取姓名
            NSString * firstName = contact.givenName;
            NSString * lastName = contact.familyName;
            //判断姓名null
            NSString *allName;
            if ([self checkStringIsNull:lastName] && [self  checkStringIsNull:firstName]) {
                allName = [NSString stringWithFormat:@"%@%@",lastName,firstName];
            }else if([self  checkStringIsNull:firstName]){
                allName = firstName;
            }else if ([self  checkStringIsNull:lastName]){
                allName = lastName;
            }else{
                allName = @"";
            }
            
            // 6.2 获取电话
            NSArray * phoneArray = contact.phoneNumbers;
            for (CNLabeledValue * labelValue in phoneArray) {
                
                CNPhoneNumber * number = labelValue.value;
                NSString *phoneNumber = number.stringValue;
                //判断手机号null
                NSString *phone;
                if ([self checkStringIsNull:phoneNumber]) {
                    phone = phoneNumber;
                }else{
                    phone = @"";
                }
                [contacts addObject:@{@"name": allName, @"phone": phone}];
            }
        }];
        return contacts;
    }else{//无权限访问
        //提示授权
        [self showAlert];
        return nil;
    }
}

- (void)requestAuthorizationAddressBook{
    //用户授权
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {//首次访问通讯录
        ABAddressBookRef addressBook = ABAddressBookCreate();        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (!error) {
                if (granted) {//允许
                    NSLog(@"允许");
                }else{//拒绝
                    NSLog(@"拒绝");
                }
            }else{
                NSLog(@"错误!");
            }
        });
    }else{//非首次访问通讯录
        
    }
}

- (NSMutableArray *)fetchContactWithAddressBook{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {////有权限访问
        ABAddressBookRef addressBook = ABAddressBookCreate();        //获取联系人数组
        CFArrayRef allLinkPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
        //获取联系人总数
        CFIndex number = ABAddressBookGetPersonCount(addressBook);
        NSMutableArray *contacts = [NSMutableArray array];
        //进行遍历
        for (int i = 0; i < number; i++) {
            //获取联系人对象的引用
            ABRecordRef  people = CFArrayGetValueAtIndex(allLinkPeople, i);
            
            //获取当前联系人名字
            NSString * firstName = (__bridge NSString *)(ABRecordCopyValue(people, kABPersonFirstNameProperty));
            //获取当前联系人姓氏
            NSString * lastName=(__bridge NSString *)(ABRecordCopyValue(people, kABPersonLastNameProperty));
            //判断姓名null
            NSString *allName;
            if ([self checkStringIsNull:lastName] && [self  checkStringIsNull:firstName]) {
                allName = [NSString stringWithFormat:@"%@%@",lastName,firstName];
            }else if([self  checkStringIsNull:firstName]){
                allName = firstName;
            }else if ([self  checkStringIsNull:lastName]){
                allName = lastName;
            }else{
                allName = @"";
            }
            
            //获取当前联系人的电话 数组
            ABMultiValueRef phones= ABRecordCopyValue(people, kABPersonPhoneProperty);
            for (NSInteger j = 0; j < ABMultiValueGetCount(phones); j++) {
                NSString *phoneNumber =(__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, j));
                //判断手机号null
                NSString *phone;
                if ([self checkStringIsNull:phoneNumber]) {
                    phone = phoneNumber;
                }else{
                    phone = @"";
                }
                [contacts addObject:@{@"name": allName, @"phone": phone}];
            }
        }
        return contacts;
    }else{//无权限访问
        //提示授权
        [self showAlert];
        return nil;
    }
}
- (void)showAlert{
    UIAlertView * alart = [[UIAlertView alloc]initWithTitle:@"温馨提示" message:@"请您设置允许APP访问您的通讯录\n设置-隐私-通讯录" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alart show];
}
- (void)saveAddressBook:(NSArray *)contacts{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:contacts options:kNilOptions error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //[jsonString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"保存成功");
    self.tContacts.text = jsonString;
}

- (BOOL) checkStringIsNull:(NSString *)string {
    if (string == nil || string == NULL) {
        return NO;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return NO;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return NO;
    }
    return YES;
} @end
