import router from '@ohos.router';
import hilog from '@ohos.hilog';
import { BookingConstants } from '../constants/BookingConstants';
import { AccountBookModel } from '../model/AccountBookModel';
import { BookDBHelper } from '../database/BookDBHelper';


export class RouteParam {
  accountId: number = 0;
}

@Entry
@Component
struct AccountBookListPage {
  @State accountBooks: AccountBookModel[] = [];
  @State isLoading: boolean = true;
  private dbHelper: BookDBHelper = BookDBHelper.getInstance();
  
  aboutToAppear() {
    this.loadAccountBooks();
  }
  
  async loadAccountBooks() {
    try {
      this.isLoading = true;
      this.accountBooks = await this.dbHelper.getAllAccountBooks();
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Load account books failed: %{private}s', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }
  
  async setDefaultAccountBook(accountId: number) {
    try {
      const result = await this.dbHelper.setDefaultAccountBook(accountId);
      if (result) {
        this.loadAccountBooks();
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Set default account book failed: %{private}s', JSON.stringify(err));
    }
  }
  
  async deleteAccountBook(accountId: number) {
    try {
      const accountBook = this.accountBooks.find(ab => ab.id === accountId);
      if (!accountBook) {
        return;
      }
      
      if (accountBook.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT) {
        return;
      }
      
      const result = await this.dbHelper.deleteAccountBook(accountId);
      if (result) {
        this.loadAccountBooks();
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Delete account book failed: %{private}s', JSON.stringify(err));
    }
  }
  
  private navigateToEdit(accountBookId: number): void {
    router.pushUrl({
      url: BookingConstants.ACCOUNT_BOOK_EDIT_ROUTE,
      params: { id: accountBookId }
    });
  }
  
  build() {
    Column() {
      Row()
        .height(20)

      TitleBar()
      
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
                onSetDefault: (): Promise<void> => this.setDefaultAccountBook(accountBook.id || 0),
                onDelete: (): Promise<void> => this.deleteAccountBook(accountBook.id || 0),
                onEdit: () => this.navigateToEdit(accountBook.id || 0)
              })
            }
          }, (item: AccountBookModel) => item.id ? item.id.toString() : '')
        }
        .width('100%')
        .layoutWeight(1)
      }

      Row()
        .height(15)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ top: 10, bottom: 10 })
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
      
      Text('账本管理')
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
  accountBook: AccountBookModel = new AccountBookModel('', 0, 0, $r('app.media.ic_other'), 0);
  onSetDefault: () => void = () => {};
  onDelete: () => void = () => {};
  onEdit: () => void = () => {};
  
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
      Image(this.accountBook.icon)
        .width(40)
        .height(40)
        .margin({ right: 16 })
      
      Column() {
        Text(this.accountBook.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        
        Text(`余额: ${this.accountBook.balance}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ top: 4 })
        
        if (this.accountBook.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT) {
          Text('默认账本')
            .fontSize(12)
            .fontColor('#4CAF50')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      if (this.accountBook.isDefault !== BookingConstants.ACCOUNT_IS_DEFAULT) {
        Row() {
          this.IconButton($r('app.media.ic_misc_cartoon_new'), this.onSetDefault)
          this.IconButton($r('app.media.ic_edit_cartoon_new'), this.onEdit)
          this.IconButton($r('app.media.ic_delete_cartoon_new'), this.onDelete)
        }
      } else {
        this.IconButton($r('app.media.ic_edit_cartoon_new'), this.onEdit)
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
      Image($r('app.media.ic_empty_cartoon_new'))
        .width(100)
        .height(100)
      
      Text('暂无账本数据')
        .fontSize(16)
        .fontColor('#666')
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
