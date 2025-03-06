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
import common from '../utils/common';
import { DBHelper } from '../database/DBHelper';
import { BookingConstants } from '../constants/BookingConstants';
import { AccountBookModel } from '../model/AccountBookModel';

@Entry
@Component
export struct TransferPage {
  @State fromAccountId: number = 0;
  @State toAccountId: number = 0;
  @State amount: number = 0;
  @State description: string = '';
  @State accountBooks: AccountBookModel[] = [];
  @State isLoading: boolean = true;
  
  private dbHelper: DBHelper = DBHelper.getInstance();
  
  aboutToAppear() {
    this.loadAccountBooks();
  }
  
  /**
   * 加载账本列表
   */
  async loadAccountBooks() {
    try {
      this.isLoading = true;
      this.accountBooks = await this.dbHelper.getAllAccountBooks();
      
      // 默认选择第一个账本作为转出账本
      if (this.accountBooks.length > 0) {
        this.fromAccountId = this.accountBooks[0].id || 0;
        
        // 如果有两个或更多账本，默认选择第二个作为转入账本
        if (this.accountBooks.length > 1) {
          this.toAccountId = this.accountBooks[1].id || 0;
        }
      }
    } catch (err) {
      hilog.error(0x0000, 'TransferPage', 'Load account books failed: %{private}s', JSON.stringify(err));
      prompt.showToast({
        message: '加载账本列表失败'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 执行转账操作
   */
  async executeTransfer() {
    // 表单验证
    if (this.fromAccountId === this.toAccountId) {
      prompt.showToast({
        message: '转出和转入账本不能相同'
      });
      return;
    }
    
    if (this.amount <= 0) {
      prompt.showToast({
        message: '转账金额必须大于0'
      });
      return;
    }
    
    // 检查转出账本余额是否足够
    const fromAccount = this.accountBooks.find(account => account.id === this.fromAccountId);
    if (fromAccount && fromAccount.balance < this.amount) {
      prompt.showToast({
        message: '转出账本余额不足'
      });
      return;
    }
    
    try {
      this.isLoading = true;
      
      // 执行转账
      const result = await this.dbHelper.executeTransfer(
        this.fromAccountId,
        this.toAccountId,
        this.amount,
        this.description,
        new Date().getTime()
      );
      
      if (result) {
        prompt.showToast({
          message: '转账成功'
        });
        setTimeout(() => router.back(), 1500);
      } else {
        prompt.showToast({
          message: '转账失败'
        });
      }
    } catch (err) {
      hilog.error(0x0000, 'TransferPage', 'Execute transfer failed: %{private}s', JSON.stringify(err));
      prompt.showToast({
        message: '转账操作失败'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 获取账本名称
   */
  getAccountName(accountId: number): string {
    const account = this.accountBooks.find(account => account.id === accountId);
    return account ? account.name : '';
  }
  
  build() {
    Column() {
      // 标题栏
      TitleBar()
      
      // 转账表单
      if (this.isLoading) {
        LoadingComponent()
      } else if (this.accountBooks.length < 2) {
        EmptyComponent()
      } else {
        Column() {
          // 转出账本选择
          FormItem({
            label: '转出账本',
            required: true,
            content: Select(this.getAccountName(this.fromAccountId))
              .options(this.accountBooks.map(account => account.name))
              .selected(this.accountBooks.findIndex(account => account.id === this.fromAccountId))
              .value(this.getAccountName(this.fromAccountId))
              .onSelect((index: number) => {
                if (index >= 0 && index < this.accountBooks.length) {
                  const selectedAccount = this.accountBooks[index];
                  if (selectedAccount && selectedAccount.id !== undefined) {
                    this.fromAccountId = selectedAccount.id;
                  }
                }
              })
          })
          
          // 转入账本选择
          FormItem({
            label: '转入账本',
            required: true,
            content: Select(this.getAccountName(this.toAccountId))
              .options(this.accountBooks.map(account => account.name))
              .selected(this.accountBooks.findIndex(account => account.id === this.toAccountId))
              .value(this.getAccountName(this.toAccountId))
              .onSelect((index: number) => {
                if (index >= 0 && index < this.accountBooks.length) {
                  const selectedAccount = this.accountBooks[index];
                  if (selectedAccount && selectedAccount.id !== undefined) {
                    this.toAccountId = selectedAccount.id;
                  }
                }
              })
          })
          
          // 转账金额
          FormItem({
            label: '转账金额',
            required: true,
            content: TextInput({ text: this.amount > 0 ? this.amount.toString() : '' })
              .height(50)
              .backgroundColor(Color.White)
              .type(InputType.Number)
              .placeholder('请输入转账金额')
              .onChange((value: string) => {
                this.amount = parseFloat(value) || 0;
              })
          })
          
          // 转账说明
          FormItem({
            label: '转账说明',
            content: TextInput({ text: this.description })
              .height(50)
              .backgroundColor(Color.White)
              .placeholder('请输入转账说明（可选）')
              .onChange((value: string) => {
                this.description = value;
              })
          })
          
          // 账户余额展示
          if (this.fromAccountId > 0) {
            const fromAccount = this.accountBooks.find(account => account.id === this.fromAccountId);
            if (fromAccount) {
              Text(`当前账户余额: ${common.formatAmount(fromAccount.balance)}`)
                .fontSize(14)
                .fontColor('#666')
                .width('100%')
                .margin({ top: 16, bottom: 8 })
            }
          }
          
          // 转账按钮
          Button('确认转账')
            .width('90%')
            .height(50)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .borderRadius(8)
            .margin({ top: 40 })
            .onClick(() => this.executeTransfer())
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
      
      Text('账本转账')
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

@Component
struct EmptyComponent {
  build() {
    Column() {
      Image($r('app.media.ic_empty' + BookingConstants.CARTOON_NEW_SUFFIX))
        .width(100)
        .height(100)
      
      Text('至少需要两个账本才能进行转账')
        .fontSize(16)
        .fontColor('#666')
        .margin({ top: 10 })
      
      Button('添加账本')
        .width('50%')
        .height(40)
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .borderRadius(8)
        .margin({ top: 20 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/AccountBookEditPage'
          });
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
