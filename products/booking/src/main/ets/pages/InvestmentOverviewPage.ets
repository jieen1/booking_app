/**
 * 投资账本概览页面
 */
import router from '@ohos.router';
import { InvestmentBookModel } from '../model/InvestmentBookModel';
import { InvestmentBookDBHelper } from '../database/InvestmentBookDBHelper';
import { InvestmentSummaryComponent } from '../components/investment/InvestmentSummaryComponent';
import { InvestmentBookCard } from '../components/investment/InvestmentBookCard';

// 添加路由参数类型
interface RouterParams {
  bookId: number;
  bookName: string;
  tradeType?: string; // 添加可选的tradeType参数
}

@Entry
@Component
export struct InvestmentOverviewPage {
  @State investmentBooks: InvestmentBookModel[] = [];
  @State totalAssets: number = 0;
  @State totalProfit: number = 0;
  @State totalProfitRate: number = 0;
  @State isLoading: boolean = true;
  @State isEmpty: boolean = false;
  @State currentInvestmentBook: InvestmentBookModel | null = null;
  
  aboutToAppear() {
    this.loadInvestmentBooks();
  }
  
  async loadInvestmentBooks() {
    try {
      this.isLoading = true;
      const bookHelper = InvestmentBookDBHelper.getInstance();
      const books = await bookHelper.getAllInvestmentBooks();
      this.investmentBooks = books;
      this.isEmpty = books.length === 0;
      
      if (!this.isEmpty) {
        this.currentInvestmentBook = books.length > 0 ? books[0] : null;
        await this.calculateSummary();
      }
    } catch (error) {
      console.error('加载投资账本列表失败', error);
    } finally {
      this.isLoading = false;
    }
  }
  
  async calculateSummary() {
    try {
      let totalAssets = 0;
      let totalCost = 0;
      
      for (const book of this.investmentBooks) {
        totalAssets += book.balance || 0;
        totalCost += book.initialInvestment || 0;
      }
      
      this.totalAssets = totalAssets;
      this.totalProfit = totalAssets - totalCost;
      this.totalProfitRate = totalCost > 0 ? (this.totalProfit / totalCost) * 100 : 0;
    } catch (error) {
      console.error('计算投资概况失败', error);
    }
  }
  
  handleBuyClick(): void {
    // 跳转到统一的交易页面，并指定为买入模式
    router.pushUrl({
      url: 'pages/InvestmentTransactionPage',
      params: {
        bookId: this.currentInvestmentBook?.id || -1,
        bookName: this.currentInvestmentBook?.name || '投资账本',
        tradeType: 'buy'
      } as RouterParams
    });
  }
  
  handleSellClick(): void {
    // 跳转到统一的交易页面，并指定为卖出模式
    router.pushUrl({
      url: 'pages/InvestmentTransactionPage',
      params: {
        bookId: this.currentInvestmentBook?.id || -1,
        bookName: this.currentInvestmentBook?.name || '投资账本',
        tradeType: 'sell'
      } as RouterParams
    });
  }
  
  handleTransferClick(): void {
    // 跳转到转账页面
    router.pushUrl({
      url: 'pages/investment/InvestmentTransferPage',
      params: {
        bookId: this.currentInvestmentBook?.id || -1,
        bookName: this.currentInvestmentBook?.name || '投资账本'
      } as RouterParams
    });
  }
  
  build() {
    Stack({ alignContent: Alignment.TopStart }) {

      Column() {
        Row()
          .height(20)

        // 页面标题
        Row() {
          Text('投资账本')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .padding({ left: 16 })
          
          Blank()
          
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.ic_add'))
              .width(24)
              .height(24)
          }
          .width(40)
          .height(40)
          .margin({ right: 16 })
          .onClick(() => {
            // 跳转到添加投资账本页面
            router.pushUrl({ url: 'pages/AccountBookEditPage', params: { isInvestment: true } });
          })
        }
        .width('100%')
        .height(60)
        .padding({ left: 16, right: 16 })
        
        if (this.isLoading) {
          // 加载中提示
          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
            
            Text('正在加载...')
              .fontSize(16)
              .margin({ top: 8 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.isEmpty) {
          // 空白提示
          Column() {
            Image($r('app.media.ic_empty'))
              .width(120)
              .height(120)
              .opacity(0.6)
            
            Text('暂无投资账本')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 16 })
            
            Button('添加投资账本')
              .backgroundColor('#4fc08d')
              .fontColor(Color.White)
              .borderRadius(20)
              .margin({ top: 24 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/AccountBookEditPage', params: { isInvestment: true } });
              })
          }
          .width('100%')
          .height('60%')
          .justifyContent(FlexAlign.Center)
        } else {
          // 投资概况组件
          InvestmentSummaryComponent({
            totalAssets: this.totalAssets,
            totalProfit: this.totalProfit,
            totalProfitRate: this.totalProfitRate,
            onBuyClick: () => this.handleBuyClick(),
            onSellClick: () => this.handleSellClick(),
            onTransferClick: () => this.handleTransferClick(),
            onAddInstrument: () => {
              // 跳转到统一的交易页面，并指定为买入模式
              router.pushUrl({
                url: 'pages/investment/InvestmentTradePage',
                params: {
                  bookId: this.currentInvestmentBook?.id || -1,
                  bookName: this.currentInvestmentBook?.name || '投资账本',
                  tradeType: 'buy'
                } as RouterParams
              });
            }
          })
          .margin({ top: 16, left: 16, right: 16 })
          
          // 投资账本列表
          List() {
            ForEach(this.investmentBooks, (book: InvestmentBookModel) => {
              ListItem() {
                InvestmentBookCard({ book: book })
              }
              .padding({ left: 16, right: 16})
            })
          }
          .width('100%')
          .layoutWeight(1)
          .margin({ top: 16 })
        }

        Row()
          .height(65)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f8f8f8')
    }
    .width('100%')
    .height('100%')
  }
}
