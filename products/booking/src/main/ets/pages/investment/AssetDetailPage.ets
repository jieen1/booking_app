/**
 * 投资资产详情页面
 * 用于显示投资资产的详细信息和市场行情数据
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { InvestmentAssetModel } from '../../model/InvestmentAssetModel';
import { InvestmentAssetDBHelper } from '../../database/InvestmentAssetDBHelper';
import { MarketQuoteModel } from '../../model/MarketQuoteModel';
import { MarketQuoteDBHelper } from '../../database/MarketQuoteDBHelper';
import { DBConnectionHolder } from '../../database/DBConnectionHolder';

// 路由参数接口
interface RouterParams {
  assetId: number;
  bookId: number;
}

@Entry
@Component
struct AssetDetailPage {
  @State asset: InvestmentAssetModel | null = null;
  @State quote: MarketQuoteModel | null = null;
  @State isLoading: boolean = true;
  @State bookId: number = -1;
  @State assetId: number = -1;
  
  // 数据库帮助类
  private assetDBHelper: InvestmentAssetDBHelper = new InvestmentAssetDBHelper();
  private quoteDBHelper: MarketQuoteDBHelper = new MarketQuoteDBHelper();
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouterParams;
    if (params) {
      this.assetId = params.assetId;
      this.bookId = params.bookId;
      this.loadData();
    } else {
      promptAction.showToast({
        message: '参数错误',
        duration: 2000
      });
      router.back();
    }
  }
  
  /**
   * 加载数据
   */
  async loadData() {
    if (this.assetId <= 0) {
      return;
    }
    
    try {
      this.isLoading = true;
      
      // 初始化数据库连接
      const dbHolder = DBConnectionHolder.getInstance();
      await dbHolder.initDB();
      
      // 加载资产数据
      const asset = await this.assetDBHelper.getInvestmentAssetById(this.assetId);
      if (asset) {
        this.asset = asset;
        
        // 加载行情数据
        const quote = await this.quoteDBHelper.getQuoteByCode(asset.code);
        if (quote) {
          this.quote = quote;
        }
      } else {
        promptAction.showToast({
          message: '资产不存在',
          duration: 2000
        });
        router.back();
      }
    } catch (error) {
      console.error('加载资产详情失败', error);
      promptAction.showToast({
        message: `加载资产详情失败: ${error.message || '未知错误'}`,
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 更新市场行情
   */
  handleUpdateQuote() {
    // 跳转到行情录入页面
    router.pushUrl({
      url: 'pages/investment/MarketQuotePage',
      params: {
        bookId: this.bookId,
        assetId: this.assetId
      }
    });
  }
  
  // 格式化涨跌额
  formatChangeAmount(amount: number): string {
    return amount >= 0 ? `+${amount.toFixed(2)}` : `${amount.toFixed(2)}`;
  }
  
  // 格式化涨跌幅
  formatChangePercent(percent: number): string {
    return percent >= 0 ? `+${percent.toFixed(2)}%` : `${percent.toFixed(2)}%`;
  }
  
  // 获取涨跌颜色
  getChangeColor(change: number): string {
    return change > 0 ? '#f44336' : change < 0 ? '#4caf50' : '#999999';
  }
  
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Row()
          .height(20)
        // 顶部导航栏
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .margin({ left: 16 })
            .onClick(() => {
              router.back();
            })
          
          Text('资产详情')
            .fontSize(18)
            .fontWeight(500)
            .margin({ left: 16 })
          
          Blank()
        }
        .width('100%')
        .height(56)
        .backgroundColor('#FFFFFF')
        
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
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (!this.asset) {
          // 资产不存在提示
          Column() {
            Image($r('app.media.ic_empty'))
              .width(120)
              .height(120)
              .opacity(0.6)
            
            Text('资产不存在')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 16 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // 资产信息
          Scroll() {
            Column() {
              // 资产基本信息卡片
              Column() {
                Row() {
                  Text(this.asset.name)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                  
                  Blank()
                  
                  Text(this.asset.code)
                    .fontSize(16)
                    .fontColor('#666666')
                }
                .width('100%')
                .padding({ bottom: 16 })
                
                // 当前价格和涨跌幅
                if (this.quote) {
                  Row() {
                    Column() {
                      Text('当前价格')
                        .fontSize(14)
                        .fontColor('#666666')
                      
                      Text(`${this.quote.currentPrice.toFixed(2)}`)
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .margin({ top: 4 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    
                    Blank()
                    
                    Column() {
                      Row() {
                        Text('涨跌额')
                          .fontSize(14)
                          .fontColor('#666666')
                        
                        Text(this.formatChangeAmount(this.quote.changeAmount))
                          .fontSize(16)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(this.getChangeColor(this.quote.changeAmount))
                          .margin({ left: 8 })
                      }
                      
                      Row() {
                        Text('涨跌幅')
                          .fontSize(14)
                          .fontColor('#666666')
                        
                        Text(this.formatChangePercent(this.quote.changePercent))
                          .fontSize(16)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(this.getChangeColor(this.quote.changePercent))
                          .margin({ left: 8, top: 8 })
                      }
                    }
                    .alignItems(HorizontalAlign.End)
                  }
                  .width('100%')
                  .padding({ top: 16, bottom: 16 })
                  
                  // 更新时间
                  Row() {
                    Text('更新时间')
                      .fontSize(14)
                      .fontColor('#666666')
                    
                    Blank()
                    
                    Text(new Date(this.quote.updateTime).toLocaleString())
                      .fontSize(14)
                      .fontColor('#666666')
                  }
                  .width('100%')
                } else {
                  // 无行情数据提示
                  Column() {
                    Text('暂无行情数据')
                      .fontSize(16)
                      .fontColor('#999999')
                      .margin({ top: 16, bottom: 16 })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                }
                
                // 更新行情按钮
                Button({
                  type: ButtonType.Capsule
                }) {
                  Row() {
                    Text('更新行情')
                      .fontSize(16)
                      .fontColor(Color.White)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                }
                .width('100%')
                .height(44)
                .backgroundColor('#4fc08d')
                .margin({ top: 24 })
                .onClick(() => {
                  this.handleUpdateQuote();
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .margin({ top: 16 })
              
              // 持仓信息卡片
              Column() {
                Text('持仓信息')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .padding({ bottom: 16 })
                
                // 持仓数量
                Row() {
                  Text('持仓数量')
                    .fontSize(14)
                    .fontColor('#666666')
                  
                  Blank()
                  
                  Text(`${this.asset.quantity}`)
                    .fontSize(16)
                    .fontWeight(500)
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
                
                // 成本价
                Row() {
                  Text('成本价')
                    .fontSize(14)
                    .fontColor('#666666')
                  
                  Blank()
                  
                  Text(`${(this.asset.cost / this.asset.quantity).toFixed(2)}`)
                    .fontSize(16)
                    .fontWeight(500)
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
                
                // 总成本
                Row() {
                  Text('总成本')
                    .fontSize(14)
                    .fontColor('#666666')
                  
                  Blank()
                  
                  Text(`${this.asset.cost.toFixed(2)}`)
                    .fontSize(16)
                    .fontWeight(500)
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
                
                // 市值
                Row() {
                  Text('当前市值')
                    .fontSize(14)
                    .fontColor('#666666')
                  
                  Blank()
                  
                  Text(`${this.asset.marketValue.toFixed(2)}`)
                    .fontSize(16)
                    .fontWeight(500)
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
                
                // 盈亏
                Row() {
                  Text('盈亏')
                    .fontSize(14)
                    .fontColor('#666666')
                  
                  Blank()
                  
                  Text(`${this.asset.profit >= 0 ? '+' : ''}${this.asset.profit.toFixed(2)}`)
                    .fontSize(16)
                    .fontWeight(500)
                    .fontColor(this.asset.profit >= 0 ? '#f44336' : '#4caf50')
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
                
                // 盈亏比例
                Row() {
                  Text('盈亏比例')
                    .fontSize(14)
                    .fontColor('#666666')
                  
                  Blank()
                  
                  Text(`${this.asset.profitRate >= 0 ? '+' : ''}${this.asset.profitRate.toFixed(2)}%`)
                    .fontSize(16)
                    .fontWeight(500)
                    .fontColor(this.asset.profitRate >= 0 ? '#f44336' : '#4caf50')
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .margin({ top: 16, bottom: 16 })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f8f8f8')
    }
    .width('100%')
    .height('100%')
  }
}
