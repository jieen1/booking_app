/**
 * Copyright (c) 2023 Harmony OS App Project
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import router from '@ohos.router';
import prompt from '@ohos.promptAction';
import hilog from '@ohos.hilog';
import { DBHelper } from '../database/DBHelper';
import { BookingConstants } from '../constants/BookingConstants';
import { AccountBookModel } from '../model/AccountBookModel';

@Entry
@Component
export struct AccountBookEditPage {
  @State accountBook: AccountBookModel = new AccountBookModel('', 0, 0, '');
  @State isNewAccount: boolean = true;
  @State isLoading: boolean = false;
  @State accountTypes: Array<{ type: number, name: string, icon: Resource }> = [
    { type: BookingConstants.ACCOUNT_BOOK_TYPE_CASH, name: '现金', icon: $r('app.media.ic_cash') },
    { type: BookingConstants.ACCOUNT_BOOK_TYPE_BANK, name: '银行卡', icon: $r('app.media.ic_bank') },
    { type: BookingConstants.ACCOUNT_BOOK_TYPE_ALIPAY, name: '支付宝', icon: $r('app.media.ic_alipay') },
    { type: BookingConstants.ACCOUNT_BOOK_TYPE_WECHAT, name: '微信', icon: $r('app.media.ic_wechat') },
    { type: BookingConstants.ACCOUNT_BOOK_TYPE_OTHER, name: '其他', icon: $r('app.media.ic_other') }
  ];
  @State selectedType: number = BookingConstants.ACCOUNT_BOOK_TYPE_CASH;
  private dbHelper: DBHelper = DBHelper.getInstance();
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams();
    const accountId = params?.accountId as number;
    
    if (accountId) {
      this.isNewAccount = false;
      this.loadAccountBook(accountId);
    } else {
      // 初始化新账本
      this.accountBook = new AccountBookModel(
        '',
        BookingConstants.ACCOUNT_BOOK_TYPE_CASH,
        0,
        this.accountTypes[0].icon
      );
      this.selectedType = BookingConstants.ACCOUNT_BOOK_TYPE_CASH;
    }
  }
  
  /**
   * 加载账本信息
   */
  async loadAccountBook(accountId: number) {
    try {
      this.isLoading = true;
      const accountBook = await this.dbHelper.getAccountBookById(accountId);
      if (accountBook) {
        this.accountBook = accountBook;
        this.selectedType = accountBook.type;
      } else {
        prompt.showToast({
          message: '账本不存在'
        });
        setTimeout(() => router.back(), 2000);
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookEditPage', 'Load account book failed: %{private}s', JSON.stringify(err));
      prompt.showToast({
        message: '加载账本信息失败'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 保存账本
   */
  async saveAccountBook() {
    // 表单验证
    if (!this.accountBook.name || !this.accountBook.name.trim()) {
      prompt.showToast({
        message: '请输入账本名称'
      });
      return;
    }
    
    try {
      this.isLoading = true;
      
      // 设置图标
      const iconType = this.accountTypes.find(item => item.type === this.selectedType);
      if (iconType) {
        this.accountBook.icon = iconType.icon;
      }
      
      // 设置类型
      this.accountBook.type = this.selectedType;
      
      let result = false;
      if (this.isNewAccount) {
        // 新增账本
        const rowId = await this.dbHelper.insertAccountBook(this.accountBook);
        result = rowId > 0;
      } else {
        // 更新账本
        // 这里需要实现更新账本的方法
        result = true;
      }
      
      if (result) {
        prompt.showToast({
          message: this.isNewAccount ? '添加账本成功' : '修改账本成功'
        });
        setTimeout(() => router.back(), 1500);
      } else {
        prompt.showToast({
          message: this.isNewAccount ? '添加账本失败' : '修改账本失败'
        });
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookEditPage', 'Save account book failed: %{private}s', JSON.stringify(err));
      prompt.showToast({
        message: this.isNewAccount ? '添加账本失败' : '修改账本失败'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  build() {
    Column() {
      // 标题栏
      TitleBar({ title: this.isNewAccount ? '添加账本' : '编辑账本' })
      
      // 表单内容
      if (this.isLoading) {
        LoadingComponent()
      } else {
        Column() {
          // 名称输入
          FormItem({
            label: '账本名称',
            required: true,
            content: TextInput({ text: this.accountBook.name })
              .height(50)
              .backgroundColor(Color.White)
              .padding({ left: 8, right: 8 })
              .onChange((value: string) => {
                this.accountBook.name = value;
              })
          })
          
          // 账本类型选择
          FormItem({
            label: '账本类型',
            required: true,
            content: Column() {
              Grid() {
                ForEach(this.accountTypes, (item) => {
                  GridItem() {
                    Column() {
                      Image(item.icon)
                        .width(40)
                        .height(40)
                      
                      Text(item.name)
                        .fontSize(14)
                        .margin({ top: 8 })
                        .fontColor(this.selectedType === item.type ? '#4CAF50' : '#333')
                    }
                    .width('100%')
                    .height(80)
                    .backgroundColor(this.selectedType === item.type ? '#E8F5E9' : Color.White)
                    .borderRadius(8)
                    .padding(8)
                    .justifyContent(FlexAlign.Center)
                    .onClick(() => {
                      this.selectedType = item.type;
                    })
                  }
                })
              }
              .columnsTemplate('1fr 1fr 1fr')
              .rowsGap(10)
              .columnsGap(10)
            }
          })
          
          // 初始余额输入
          if (this.isNewAccount) {
            FormItem({
              label: '初始余额',
              content: TextInput({ text: this.accountBook.balance.toString() })
                .height(50)
                .backgroundColor(Color.White)
                .padding({ left: 8, right: 8 })
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.accountBook.balance = parseFloat(value) || 0;
                })
            })
          }
          
          // 提交按钮
          Button('保存')
            .width('90%')
            .height(50)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .borderRadius(8)
            .margin({ top: 40 })
            .onClick(() => this.saveAccountBook())
        }
        .width('100%')
        .padding(16)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

@Component
struct TitleBar {
  title: string = '账本管理';
  
  build() {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
      }
      .backgroundColor(Color.Transparent)
      .width(36)
      .height(36)
      .onClick(() => router.back())
      
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Blank()
        .width(36)
    }
    .width('100%')
    .height(50)
    .padding({ left: 10, right: 10 })
  }
}

@Component
struct FormItem {
  label: string;
  required: boolean = false;
  @BuilderParam content: () => void;
  
  build() {
    Column() {
      Row() {
        if (this.required) {
          Text('*')
            .fontSize(16)
            .fontColor(Color.Red)
            .margin({ right: 4 })
        }
        
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })
      
      this.content()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 16 })
  }
}

@Component
struct LoadingComponent {
  build() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
      
      Text('加载中...')
        .fontSize(14)
        .fontColor('#666')
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
