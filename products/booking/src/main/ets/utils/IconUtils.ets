import { BookingConstants } from "../constants/BookingConstants";

export class IconUtils {

  /**
   * 获取分类图标资源
   * @param icon 图标资源对象或标识符
   * @returns 图标资源
   */
  static getCategoryIcon(icon: Resource | string | undefined): Resource {
    if (icon == null) {
      return $r('app.media.ic_empty_cartoon_new');
    }
    if (typeof icon !== 'string') {
      return icon;
    }
    return IconUtils.getResourceByKey(icon);
  }

  /**
   * 根据图标标识符获取对应的资源ID
   *
   * @param iconKey 图标标识符
   * @return 资源ID
   */
  static getResourceByKey(iconKey: string): Resource {
    switch (iconKey) {
      case BookingConstants.ICON_SALARY:
        return $r('app.media.ic_salary_cartoon_new');
      case BookingConstants.ICON_BONUS:
        return $r('app.media.ic_bonus_cartoon_new');
      case BookingConstants.ICON_INVESTMENT:
        return $r('app.media.ic_investment_cartoon_new');
      case BookingConstants.ICON_PARTTIME:
        return $r('app.media.ic_parttime_cartoon_new');
      case BookingConstants.ICON_FOOD:
        return $r('app.media.ic_food_cartoon_new');
      case BookingConstants.ICON_TRANSPORT:
        return $r('app.media.ic_transport_cartoon_new');
      case BookingConstants.ICON_SHOPPING:
        return $r('app.media.ic_shopping_cartoon_new');
      case BookingConstants.ICON_HOUSING:
        return $r('app.media.ic_housing_cartoon_new');
      case BookingConstants.ICON_MEDICAL:
        return $r('app.media.ic_medical_cartoon_new');
      case BookingConstants.ICON_EDUCATION:
        return $r('app.media.ic_education_cartoon_new');
      case BookingConstants.ICON_DINING:
        return $r('app.media.ic_dining_cartoon_new');
      case BookingConstants.ICON_MISC:
      default:
        return $r('app.media.ic_misc_cartoon_new');
    }
  }

  static getIconByTypeAndName(type: number, name: string | number): Resource {
    return IconUtils.getResourceByKey(IconUtils.getIconKeyByTypeAndName(type, name))
  }

  /**
   * 获取图标标识符
   * @param type 分类类型
   * @param name 分类名称
   * @returns 图标标识符
   */
  static getIconKeyByTypeAndName(type: number, name: string | number): string {
    // 收入类型的图标映射
    if (type === BookingConstants.INCOME_TYPE) {
      switch (name) {
        case '工资':
          return BookingConstants.ICON_SALARY;
        case '奖金':
          return BookingConstants.ICON_BONUS;
        case '兼职':
          return BookingConstants.ICON_PARTTIME;
        case '投资':
          return BookingConstants.ICON_INVESTMENT;
        default:
          return BookingConstants.ICON_MISC;
      }
    }

    // 支出类型的图标映射
    if (type === BookingConstants.EXPENSE_TYPE) {
      switch (name) {
        case '餐饮':
          return BookingConstants.ICON_FOOD;
        case '购物':
          return BookingConstants.ICON_SHOPPING;
        case '交通':
          return BookingConstants.ICON_TRANSPORT;
        case '住房':
          return BookingConstants.ICON_HOUSING;
        case '娱乐':
          return BookingConstants.ICON_DINING;
        case '医疗':
          return BookingConstants.ICON_MEDICAL;
        case '教育':
          return BookingConstants.ICON_EDUCATION;
        default:
          return BookingConstants.ICON_MISC;
      }
    }

    if (type === BookingConstants.BOOK_TYPE) {
      switch (name) {
        case BookingConstants.ACCOUNT_TYPE_CASH:
        //   static readonly ACCOUNT_TYPE_CASH: string = '现金';      // 现金
      //   static readonly ACCOUNT_TYPE_BANK_CARD: string = '银行卡'; // 银行卡
      //   static readonly ACCOUNT_TYPE_ALIPAY: string = '支付宝';    // 支付宝
      //   static readonly ACCOUNT_TYPE_WECHAT: string = '微信';    // 微信
      //   static readonly ACCOUNT_TYPE_STOCK: string = '股票';    // 股票
      //   static readonly ACCOUNT_TYPE_OTHER: string = '其他';     // 其他

      }
    }

    return BookingConstants.ICON_MISC;
  }
}