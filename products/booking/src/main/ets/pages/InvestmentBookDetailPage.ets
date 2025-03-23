/**
 * 投资账本详情页面
 */
import router from '@ohos.router';
import prompt from '@ohos.prompt';
import { InvestmentBookModel, InvestmentType } from '../model/InvestmentBookModel';
import { InvestmentAssetModel } from '../model/InvestmentAssetModel';
import { InvestmentBookDBHelper } from '../database/InvestmentBookDBHelper';
import { InvestmentAssetDBHelper } from '../database/InvestmentAssetDBHelper';
import { InvestmentAssetList } from '../components/investment/InvestmentAssetList';
import { InvestmentProfitComponent } from '../components/investment/InvestmentProfitComponent';

@Entry
@Component
export struct InvestmentBookDetailPage {
  @State book: InvestmentBookModel = new InvestmentBookModel('', InvestmentType.STOCK, 0);
  @State assets: InvestmentAssetModel[] = [];
  @State isLoading: boolean = true;
  @State isEmpty: boolean = false;
  private bookId: number = 0;
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, number>;
    if (params && params.bookId) {
      this.bookId = params.bookId;
      this.loadBookData();
    } else {
      prompt.showToast({
        message: '账本ID无效',
        duration: 2000
      });
      router.back();
    }
  }
  
  async loadBookData() {
    try {
      this.isLoading = true;
      
      // 加载账本基本信息
      const bookHelper = InvestmentBookDBHelper.getInstance();
      const book = await bookHelper.getInvestmentBookById(this.bookId);
      
      if (book) {
        this.book = book;
        
        // 加载该账本下的投资品种
        const assetHelper = InvestmentAssetDBHelper.getInstance();
        const assets = await assetHelper.getAssetsByBookId(this.bookId);
        this.assets = assets;
        this.isEmpty = assets.length === 0;
      } else {
        prompt.showToast({
          message: '账本不存在',
          duration: 2000
        });
        router.back();
      }
    } catch (error) {
      console.error('加载投资账本详情失败', error);
      prompt.showToast({
        message: '加载失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button({
          type: ButtonType.Circle,
          stateEffect: true
        }) {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
        }
        .width(36)
        .height(36)
        .backgroundColor('rgba(255, 255, 255, 0.6)')
        .onClick(() => {
          router.back();
        })
        
        Blank()
        
        Button({
          type: ButtonType.Circle,
          stateEffect: true
        }) {
          Image($r('app.media.ic_edit_cartoon_new'))
            .width(20)
            .height(20)
        }
        .width(36)
        .height(36)
        .backgroundColor('rgba(255, 255, 255, 0.6)')
        .onClick(() => {
          router.pushUrl({
            url: 'pages/AccountBookEditPage',
            params: {
              isInvestment: true,
              bookId: this.bookId
            }
          });
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })
      
      // 账本基本信息
      Row() {
        Image(this.book.icon || $r('app.media.ic_investment'))
          .width(60)
          .height(60)
          .borderRadius(30)
        
        Column() {
          Text(this.book.name)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      
      // 收益信息组件
      InvestmentProfitComponent({
        book: this.book,
        assets: this.assets
      })
      .margin({ left: 16, right: 16, bottom: 16 })
      
      // 操作按钮
      Row() {
        Button({
          type: ButtonType.Capsule
        }) {
          Row() {
            Image($r('app.media.ic_buy'))
              .width(20)
              .height(20)
              .margin({ right: 8 })
            
            Text('买入')
              .fontSize(16)
              .fontColor(Color.White)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
        .height(44)
        .backgroundColor('#ff9800')
        .layoutWeight(1)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/investment/InvestmentTradePage',
            params: {
              bookId: this.bookId,
              tradeType: 'buy'
            }
          });
        })
        
        Blank()
          .width(12)
        
        Button({
          type: ButtonType.Capsule
        }) {
          Row() {
            Image($r('app.media.ic_sell'))
              .width(20)
              .height(20)
              .margin({ right: 8 })
            
            Text('卖出')
              .fontSize(16)
              .fontColor(Color.White)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
        .height(44)
        .backgroundColor('#4caf50')
        .layoutWeight(1)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/investment/InvestmentTradePage',
            params: {
              bookId: this.bookId,
              tradeType: 'sell'
            }
          });
        })
        
        Blank()
          .width(12)
        
        Button({
          type: ButtonType.Capsule
        }) {
          Row() {
            Image($r('app.media.ic_add_asset'))
              .width(20)
              .height(20)
              .margin({ right: 8 })
            
            Text('添加品种')
              .fontSize(16)
              .fontColor(Color.White)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
        .height(44)
        .backgroundColor('#2196f3')
        .layoutWeight(1)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/InvestmentAssetEditPage',
            params: {
              bookId: this.bookId
            }
          });
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
      
      // 投资品种列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#4fc08d')
          
          Text('正在加载...')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.isEmpty) {
        Column() {
          Image($r('app.media.ic_empty'))
            .width(100)
            .height(100)
            .opacity(0.6)
          
          Text('暂无投资品种')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 })
          
          Button('添加投资品种')
            .backgroundColor('#4fc08d')
            .fontColor(Color.White)
            .borderRadius(20)
            .margin({ top: 16 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/InvestmentAssetEditPage',
                params: {
                  bookId: this.bookId
                }
              });
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          // 投资品种列表标题
          Row() {
            Text('投资品种')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            
            Blank()
            
            Text('查看全部')
              .fontSize(14)
              .fontColor('#4fc08d')
              .onClick(() => {
                // 可以跳转到一个专门的品种列表页面
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          
          // 投资品种列表
          InvestmentAssetList({
            assets: this.assets,
            bookId: this.bookId,
            onRefresh: (): Promise<void> => this.loadBookData()
          })
          .layoutWeight(1)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
  }
}
