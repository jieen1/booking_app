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
export struct AccountBookListPage {
  @State accountBooks: AccountBookModel[] = [];
  @State isLoading: boolean = true;
  private dbHelper: DBHelper = DBHelper.getInstance();
  
  aboutToAppear() {
    this.loadAccountBooks();
  }
  
  /**
   * u52a0u8f7du8d26u672cu5217u8868
   */
  async loadAccountBooks() {
    try {
      this.isLoading = true;
      this.accountBooks = await this.dbHelper.getAllAccountBooks();
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Load account books failed: %{private}s', JSON.stringify(err));
      prompt.showToast({
        message: 'u52a0u8f7du8d26u672cu5217u8868u5931u8d25'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * u8bbeu7f6eu9ed8u8ba4u8d26u672c
   */
  async setDefaultAccountBook(accountId: number) {
    try {
      const result = await this.dbHelper.setDefaultAccountBook(accountId);
      if (result) {
        prompt.showToast({
          message: 'u8bbeu7f6eu9ed8u8ba4u8d26u672cu6210u529f'
        });
        this.loadAccountBooks();
      } else {
        prompt.showToast({
          message: 'u8bbeu7f6eu9ed8u8ba4u8d26u672cu5931u8d25'
        });
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Set default account book failed: %{private}s', JSON.stringify(err));
      prompt.showToast({
        message: 'u8bbeu7f6eu9ed8u8ba4u8d26u672cu5931u8d25'
      });
    }
  }
  
  /**
   * u5220u9664u8d26u672c
   */
  async deleteAccountBook(accountId: number) {
    try {
      // u67e5u627eu8981u5220u9664u7684u8d26u672c
      const accountBook = this.accountBooks.find(ab => ab.id === accountId);
      if (!accountBook) {
        prompt.showToast({ message: 'u8d26u672cu4e0du5b58u5728' });
        return;
      }
      
      // u4e0du80fdu5220u9664u9ed8u8ba4u8d26u672c
      if (accountBook.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT) {
        prompt.showToast({ message: 'u4e0du80fdu5220u9664u9ed8u8ba4u8d26u672c' });
        return;
      }
      
      // u786eu8ba4u5220u9664
      const result = await this.dbHelper.deleteAccountBook(accountId);
      if (result) {
        prompt.showToast({ message: 'u5220u9664u8d26u672cu6210u529f' });
        this.loadAccountBooks();
      } else {
        prompt.showToast({ message: 'u5220u9664u8d26u672cu5931u8d25' });
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Delete account book failed: %{private}s', JSON.stringify(err));
      prompt.showToast({ message: 'u5220u9664u8d26u672cu5931u8d25' });
    }
  }
  
  build() {
    Column() {
      // u6807u9898u680f
      TitleBar()
      
      // u8d26u672cu5217u8868
      if (this.isLoading) {
        LoadingComponent()
      } else if (this.accountBooks.length === 0) {
        EmptyComponent()
      } else {
        List() {
          ForEach(this.accountBooks, (accountBook: AccountBookModel) => {
            ListItem() {
              AccountBookItem({
                accountBook: accountBook,
                onSetDefault: () => this.setDefaultAccountBook(accountBook.id),
                onDelete: () => this.deleteAccountBook(accountBook.id),
                onEdit: () => this.navigateToEdit(accountBook.id)
              })
            }
          }, (item: AccountBookModel) => item.id ? item.id.toString() : '')
        }
        .width('100%')
        .layoutWeight(1)
      }
      
      // u6dfbu52a0u8d26u672cu6309u94ae
      Button('u6dfbu52a0u8d26u672c')
        .width('90%')
        .height(50)
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 20 })
        .onClick(() => this.navigateToEdit())
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ top: 10, bottom: 10 })
  }
  
  /**
   * u8df3u8f6cu5230u7f16u8f91u9875u9762
   */
  navigateToEdit(accountId?: number) {
    const params: Record<string, string | number | undefined> = {
      accountId: accountId
    };
    router.pushUrl({
      url: 'pages/AccountBookEditPage',
      params: params
    });
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
      
      Text('u8d26u672cu7ba1u7406')
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
struct AccountBookItem {
  accountBook: AccountBookModel;
  onSetDefault: () => void;
  onDelete: () => void;
  onEdit: () => void;
  
  @Builder
  IconButton(icon: Resource, callback: () => void) {
    Button({ type: ButtonType.Normal }) {
      Image(icon)
        .width(20)
        .height(20)
    }
    .backgroundColor(Color.Transparent)
    .width(30)
    .height(30)
    .onClick(callback)
  }
  
  build() {
    Row() {
      // u56feu6807
      Image(this.accountBook.icon)
        .width(40)
        .height(40)
        .margin({ right: 16 })
      
      // u4fe1u606f
      Column() {
        Text(this.accountBook.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        
        Text(`u4f59u989d: ${common.formatAmount(this.accountBook.balance)}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ top: 4 })
        
        if (this.accountBook.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT) {
          Text('u9ed8u8ba4u8d26u672c')
            .fontSize(12)
            .fontColor('#4CAF50')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // u64cdu4f5cu6309u94ae
      if (this.accountBook.isDefault !== BookingConstants.ACCOUNT_IS_DEFAULT) {
        Row() {
          this.IconButton($r('app.media.ic_default'), this.onSetDefault)
          this.IconButton($r('app.media.ic_edit'), this.onEdit)
          this.IconButton($r('app.media.ic_delete'), this.onDelete)
        }
      } else {
        this.IconButton($r('app.media.ic_edit'), this.onEdit)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 10 })
  }
}

@Component
struct LoadingComponent {
  build() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
      
      Text('u52a0u8f7du4e2d...')
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
      
      Text('u6682u65e0u8d26u672cu6570u636e')
        .fontSize(16)
        .fontColor('#666')
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
