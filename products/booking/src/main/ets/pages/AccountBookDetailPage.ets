import router from '@ohos.router';
import prompt from '@ohos.promptAction';
import hilog from '@ohos.hilog';
import { BookingConstants } from '../constants/BookingConstants';
import { AccountBookModel } from '../model/AccountBookModel';
import { SummaryData, CategorySummary } from '../model/SummaryModel';
import { RecordWithCategory } from '../model/RecordWithCategory';
import { BookDBHelper } from '../database/BookDBHelper';
import { RouteParam } from './AccountBookListPage';
import { RecordModel } from '../model/RecordModel';
import { CategoryModel } from '../model/CategoryModel';

@Entry
@Component
struct AccountBookDetailPage {
  @State accountBook: AccountBookModel | null = null;
  @State records: RecordWithCategory[] = [];
  @State summary: SummaryData = { income: 0, expense: 0 };
  @State categorySummaries: CategorySummary[] = [];
  @State isLoading: boolean = true;
  @State currentTab: number = 0; // 0: 明细, 1: 统计
  @State recordType: number = BookingConstants.RECORD_TYPE_EXPENSE; // 默认显示支出分类统计
  
  private accountId: number = 0;
  private dbHelper: BookDBHelper = BookDBHelper.getInstance();
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParam;
    this.accountId = params?.accountId as number || 0;
    
    if (this.accountId > 0) {
      this.loadAccountBook();
      this.loadRecords();
      this.loadSummary();
    } else {
      prompt.showToast({
        message: '账本ID无效'
      });
      setTimeout(() => router.back(), 2000);
    }
  }
  
  /**
   * 加载账本信息
   */
  async loadAccountBook() {
    try {
      this.isLoading = true;
      this.accountBook = await this.dbHelper.getAccountBookById(this.accountId);
      if (!this.accountBook) {
        prompt.showToast({
          message: '账本不存在'
        });
        setTimeout(() => router.back(), 2000);
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookDetailPage', 'Load account book failed: %{private}s', JSON.stringify(err));
      prompt.showToast({
        message: '加载账本信息失败'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 加载账本记录
   */
  async loadRecords() {
    try {
      this.isLoading = true;
      this.records = await this.dbHelper.getRecordsByAccountBook(this.accountId);
    } catch (err) {
      hilog.error(0x0000, 'AccountBookDetailPage', 'Load records failed: %{private}s', JSON.stringify(err));
      prompt.showToast({
        message: '加载记录失败'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 加载统计数据
   */
  async loadSummary() {
    try {
      this.isLoading = true;
      // 加载收支汇总
      this.summary = await this.dbHelper.getAccountBookSummary(this.accountId);
      
      // 加载分类统计
      this.loadCategorySummary();
    } catch (err) {
      hilog.error(0x0000, 'AccountBookDetailPage', 'Load summary failed: %{private}s', JSON.stringify(err));
      prompt.showToast({
        message: '加载统计数据失败'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 加载分类统计数据
   */
  async loadCategorySummary() {
    try {
      this.categorySummaries = await this.dbHelper.getCategorySummaryByAccountBook(
        this.accountId,
        this.recordType
      );
    } catch (err) {
      hilog.error(0x0000, 'AccountBookDetailPage', 'Load category summary failed: %{private}s', JSON.stringify(err));
    }
  }
  
  /**
   * 切换记录类型（收入/支出）
   */
  async switchRecordType(type: number) {
    if (this.recordType !== type) {
      this.recordType = type;
      this.loadCategorySummary();
    }
  }
  
  build() {
    Column() {
      // 标题栏
      TitleBar({ title: this.accountBook?.name || '账本详情' })
      
      if (this.isLoading) {
        LoadingComponent()
      } else if (!this.accountBook) {
        EmptyComponent()
      } else {
        // 账本信息卡片
        AccountInfoCard({ accountBook: this.accountBook, summary: this.summary })
        
        // 选项卡
        Tabs({ barPosition: BarPosition.Start, index: this.currentTab }) {
          TabContent() {
            // 明细列表
            if (this.records.length === 0) {
              EmptyRecordsComponent()
            } else {
              List() {
                ForEach(this.records, (record: RecordWithCategory) => {
                  ListItem() {
                    RecordItem({ record: record })
                  }
                }, (item: RecordWithCategory) => item.id ? item.id.toString() : '')
              }
              .width('100%')
              .layoutWeight(1)
            }
          }
          .tabBar('明细')
          
          TabContent() {
            // 统计视图
            Column() {
              // 类型切换
              Row() {
                Button({ type: ButtonType.Capsule, stateEffect: true }) {
                  Text('支出')
                    .fontColor(this.recordType === BookingConstants.RECORD_TYPE_EXPENSE ? Color.White : '#666')
                }
                .backgroundColor(this.recordType === BookingConstants.RECORD_TYPE_EXPENSE ? '#FF6B6B' : '#F0F0F0')
                .margin({ right: 10 })
                .onClick(() => this.switchRecordType(BookingConstants.RECORD_TYPE_EXPENSE))
                
                Button({ type: ButtonType.Capsule, stateEffect: true }) {
                  Text('收入')
                    .fontColor(this.recordType === BookingConstants.RECORD_TYPE_INCOME ? Color.White : '#666')
                }
                .backgroundColor(this.recordType === BookingConstants.RECORD_TYPE_INCOME ? '#4CAF50' : '#F0F0F0')
                .onClick(() => this.switchRecordType(BookingConstants.RECORD_TYPE_INCOME))
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .margin({ top: 10, bottom: 20 })
              
              // 分类统计列表
              if (this.categorySummaries.length === 0) {
                EmptyCategoryComponent()
              } else {
                List() {
                  ForEach(this.categorySummaries, (item: CategorySummary) => {
                    ListItem() {
                      CategorySummaryItem({ item: item })
                    }
                  }, (item: CategorySummary) => item.categoryId.toString())
                }
                .width('100%')
                .layoutWeight(1)
              }
            }
            .width('100%')
            .height('100%')
          }
          .tabBar('统计')
        }
        .width('100%')
        .layoutWeight(1)
        .onChange((index: number) => {
          this.currentTab = index;
        })
        
        // 底部操作按钮
        Row() {
          Button('添加记录')
            .width('45%')
            .height(45)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .borderRadius(8)
            .onClick(() => this.navigateToAddRecord())
          
          Button('转账')
            .width('45%')
            .height(45)
            .backgroundColor('#2196F3')
            .fontColor(Color.White)
            .borderRadius(8)
            .onClick(() => this.navigateToTransfer())
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .padding({ top: 10, bottom: 10 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 跳转到添加记录页面
   */
  navigateToAddRecord() {
    router.pushUrl({
      url: 'pages/RecordEditPage',
      params: {
        accountBookId: this.accountId
      }
    });
  }
  
  /**
   * 跳转到转账页面
   */
  navigateToTransfer() {
    router.pushUrl({
      url: 'pages/TransferPage'
    });
  }
}

@Component
struct TitleBar {
  title: string = '账本详情';
  
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
struct AccountInfoCard {
  accountBook: AccountBookModel = new AccountBookModel('', 0, 0, $r('app.media.ic_other'), 0);
  summary: SummaryData = { income: 0, expense: 0 };
  
  build() {
    Column() {
      // 账本信息
      Row() {
        Image(this.accountBook.icon)
          .width(40)
          .height(40)
        
        Column() {
          Text(this.accountBook.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          
          Text(`余额: ${this.accountBook.balance}`)
            .fontSize(14)
            .fontColor('#666')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      
      // 收支统计
      Row() {
        Column() {
          Text('收入')
            .fontSize(14)
            .fontColor('#666')
          
          Text(this.summary.income + "")
            .fontSize(16)
            .fontColor('#4CAF50')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Divider()
          .vertical(true)
          .height(30)
          .color('#E0E0E0')
        
        Column() {
          Text('支出')
            .fontSize(14)
            .fontColor('#666')
          
          Text(this.summary.expense + "")
            .fontSize(16)
            .fontColor('#FF6B6B')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Divider()
          .vertical(true)
          .height(30)
          .color('#E0E0E0')
        
        Column() {
          Text('结余')
            .fontSize(14)
            .fontColor('#666')
          
          Text((this.summary.income - this.summary.expense) + "")
            .fontSize(16)
            .fontColor('#2196F3')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 10, bottom: 16 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ top: 10, bottom: 10 })
  }
}

@Component
struct RecordItem {
  record: RecordWithCategory = new RecordWithCategory(new RecordModel(0, 0, 0, '', 0), new CategoryModel(0, '', $r('app.media.ic_other')));
  
  build() {
    Row() {
      // 类别图标
      Image(this.record.category.icon)
        .width(40)
        .height(40)
      
      // 记录信息
      Column() {
        Text(this.record.category.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        
        if (this.record.description) {
          Text(this.record.description)
            .fontSize(14)
            .fontColor('#666')
            .margin({ top: 4 })
        }
        
        Text(this.record.recordTime + "")
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16 })
      .layoutWeight(1)
      
      // 金额
      Text(this.record.type === BookingConstants.RECORD_TYPE_EXPENSE ?
           `-${this.record.amount}` :
           `+${this.record.amount}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.record.type === BookingConstants.RECORD_TYPE_EXPENSE ? '#FF6B6B' : '#4CAF50')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 10 })
  }
}

@Component
struct CategorySummaryItem {
  item: CategorySummary = { categoryId: 0, categoryName: '', icon: "", amount: 0 };
  recordType: number = BookingConstants.RECORD_TYPE_EXPENSE;
  
  build() {
    Row() {
      // 类别图标
      Image(this.item.icon)
        .width(40)
        .height(40)
      
      // 类别信息
      Column() {
        Text(this.item.categoryName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16 })
      .layoutWeight(1)
      
      // 金额
      Text(this.item.amount + "")
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.recordType === BookingConstants.RECORD_TYPE_EXPENSE ? '#FF6B6B' : '#4CAF50')
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
      
      Text('账本不存在或已被删除')
        .fontSize(16)
        .fontColor('#666')
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

@Component
struct EmptyRecordsComponent {
  build() {
    Column() {
      Image($r('app.media.ic_empty_cartoon_new'))
        .width(100)
        .height(100)
      
      Text('暂无记录数据')
        .fontSize(16)
        .fontColor('#666')
        .margin({ top: 10 })
      
      Button('添加记录')
        .width('50%')
        .height(40)
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .borderRadius(8)
        .margin({ top: 20 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/RecordEditPage'
          });
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

@Component
struct EmptyCategoryComponent {
  build() {
    Column() {
      Image($r('app.media.ic_empty_cartoon_new' + BookingConstants.CARTOON_NEW_SUFFIX))
        .width(100)
        .height(100)
      
      Text('暂无分类统计数据')
        .fontSize(16)
        .fontColor('#666')
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}