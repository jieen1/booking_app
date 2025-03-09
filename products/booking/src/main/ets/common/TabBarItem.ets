interface GeneratedObjectLiteralInterface_1 {
  NORMAL: Resource;
  SELECTED: Resource;
}

const TitleColor: GeneratedObjectLiteralInterface_1 = {
  NORMAL: $r('app.color.TEXT_SECONDARY_COLOR'),
  SELECTED: $r('app.color.TEXT_PRIMARY_COLOR')
}

@Component
export default struct TabBarItem {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'md'
  @Prop currentIndex: number
  private index?:number
  private icon?:Resource
  private iconSelected?:Resource
  private title?:Resource

  private getIcon() {
    return this.currentIndex === this.index ? this.iconSelected : this.icon
  }

  private getFontColor() {
    return this.currentIndex === this.index ? TitleColor.SELECTED : TitleColor.NORMAL
  }

  build() {
    if (this.currentBreakpoint !== 'md' ) {
      Column() {
        Image(this.getIcon())
          .width(24)
          .height(24)
          .margin(5)
          .objectFit(ImageFit.Contain)
        Text(this.title)
          .fontColor(this.getFontColor())
          .fontSize(12)
          .fontWeight(500)
      }.justifyContent(FlexAlign.Center).height('100%').width('100%')
    } else {
      Row() {
        Image(this.getIcon())
          .width(24)
          .height(24)
          .margin(5)
          .objectFit(ImageFit.Contain)
        Text(this.title)
          .fontColor(this.getFontColor())
          .fontSize(12)
          .fontWeight(500)
      }.justifyContent(FlexAlign.Center).height('100%').width('100%')
    }
  }
}