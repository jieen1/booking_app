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
    switch (icon) {
      case BookingConstants.ICON_SALARY:
        return $r('app.media.ic_salary' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_BONUS:
        return $r('app.media.ic_bonus' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_PARTTIME:
        return $r('app.media.ic_parttime' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_INVESTMENT:
        return $r('app.media.ic_investment' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_FOOD:
        return $r('app.media.ic_food' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_TRANSPORT:
        return $r('app.media.ic_transport' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_SHOPPING:
        return $r('app.media.ic_shopping' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_MEDICAL:
        return $r('app.media.ic_medical' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_HOUSING:
        return $r('app.media.ic_housing' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_EDUCATION:
        return $r('app.media.ic_education' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_MISC:
        return $r('app.media.ic_misc' + BookingConstants.CARTOON_NEW_SUFFIX);
      default:
        return $r('app.media.ic_misc' + BookingConstants.CARTOON_NEW_SUFFIX);
    }
  }
}