/**
 * 投资资产选择器组件
 */
import router from '@ohos.router';
import { InvestmentAssetModel } from '../../model/InvestmentAssetModel';
import { InvestmentAssetDBHelper } from '../../database/InvestmentAssetDBHelper';

@Component
export struct AssetSelector {
  @Prop assets: InvestmentAssetModel[] = [];
  @Prop bookId: number = 0;
  @State searchText: string = '';
  @State filteredAssets: InvestmentAssetModel[] = [];
  onSelect?: (asset: InvestmentAssetModel) => void;
  
  aboutToAppear() {
    this.updateFilteredAssets();
  }
  
  updateFilteredAssets() {
    if (!this.searchText) {
      this.filteredAssets = this.assets;
      return;
    }
    
    const searchLower = this.searchText.toLowerCase();
    this.filteredAssets = this.assets.filter(asset => {
      return asset.name.toLowerCase().includes(searchLower) || 
             asset.code.toLowerCase().includes(searchLower);
    });
  }
  
  build() {
    Column() {
      // 搜索框
      TextInput({ placeholder: '搜索资产名称或代码', text: this.searchText })
        .width('100%')
        .height(48)
        .backgroundColor('#f5f5f5')
        .borderRadius(24)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.searchText = value;
          this.updateFilteredAssets();
        })
      
      // 资产列表
      if (this.filteredAssets.length > 0) {
        List() {
          ForEach(this.filteredAssets, (asset: InvestmentAssetModel) => {
            ListItem() {
              Row() {
                Column() {
                  Text(asset.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  
                  Text(asset.code)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                
                Column() {
                  Text(`¥${asset.currentPrice.toFixed(2)}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  
                  if (asset.quantity > 0) {
                    Text(`持有${asset.quantity}股`)
                      .fontSize(14)
                      .fontColor('#666666')
                      .margin({ top: 4 })
                  }
                }
                .alignItems(HorizontalAlign.End)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(Color.White)
              .borderRadius(8)
            }
            .onClick(() => {
              if (this.onSelect) {
                this.onSelect(asset);
              }
            })
          })
        }
        .width('100%')
        .divider({
          strokeWidth: 1,
          color: '#f5f5f5',
          startMargin: 8,
          endMargin: 8
        })
        .margin({ top: 16 })
        .height(300)
      } else if (this.searchText) {
        // 无搜索结果
        Column() {
          Image($r('app.media.ic_empty'))
            .width(100)
            .height(100)
            .margin({ top: 30 })
          
          Text('没有找到相关资产')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 })
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else if (this.assets.length === 0) {
        // 无资产
        Column() {
          Image($r('app.media.ic_empty'))
            .width(100)
            .height(100)
            .margin({ top: 30 })
          
          Text('暂无资产，点击添加新资产')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 })
          
          Button('添加资产')
            .width(160)
            .height(40)
            .borderRadius(20)
            .backgroundColor('#4fc08d')
            .fontColor(Color.White)
            .margin({ top: 16 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/AddAssetPage',
                params: {
                  bookId: this.bookId,
                  callback: () => {
                    // 跳转后需要刷新数据
                  }
                }
              });
            })
        }
        .width('100%')
        .height(280)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height(350)
  }
}
