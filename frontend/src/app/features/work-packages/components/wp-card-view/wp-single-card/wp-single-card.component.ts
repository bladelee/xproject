import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Injector,
  Input,
  OnInit,
  Output,
} from '@angular/core';
import {
  uiStateLinkClass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  Highlighting,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { StateService, UIRouterGlobals } from '@uirouter/core';
import {
  WorkPackageViewSelectionService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import {
  WorkPackageCardViewService,
} from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-view.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  CardHighlightingMode,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting-mode.const';
import { CardViewOrientation } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  WorkPackageViewFocusService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { BookingItem, WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { getBaselineState } from 'core-app/features/work-packages/components/wp-baseline/baseline-helpers';
import {
  CombinedDateDisplayField,
} from 'core-app/shared/components/fields/display/field-types/combined-date-display.field';

import { BookingComponent } from 'core-app/shared/components/modals/booking-modal/booking.component';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';

@Component({
  selector: 'wp-single-card',
  styleUrls: ['./wp-single-card.component.sass'],
  templateUrl: './wp-single-card.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageSingleCardComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  @Input() public selectedWhenOpen = false;

  @Input() public showInfoButton = false;

  @Input() public showStatusButton = true;

  @Input() public showRemoveButton = false;

  @Input() public highlightingMode:CardHighlightingMode = 'inline';

  @Input() public draggable = false;

  @Input() public orientation:CardViewOrientation = 'vertical';

  @Input() public shrinkOnMobile = false;

  @Input() public disabledInfo?:{ text:string, orientation:'left'|'right' };

  @Input() public showAsInlineCard = false;

  @Input() public showStartDate = true;

  @Input() public showEndDate = true;

  @Input() public isClosed = false;

  @Input() public showAsGhost = false;

  @Output() onRemove = new EventEmitter<WorkPackageResource>();

  @Output() stateLinkClicked = new EventEmitter<{ workPackageId:string, requestedState:string }>();

  @Output() cardClicked = new EventEmitter<{ workPackageId:string, event:MouseEvent }>();

  @Output() cardDblClicked = new EventEmitter<{ workPackageId:string, event:MouseEvent }>();

  @Output() cardContextMenu = new EventEmitter<{ workPackageId:string, event:MouseEvent }>();

  public uiStateLinkClass:string = uiStateLinkClass;

  public selected = false;

  public baselineMode = ''||'added'||'updated'||'removed';

  @Input() public windowStartDate: string = '';
  @Input() public windowEndDate: string = '';
  @Input() public resourceBookingItem: BookingItem | null = null;

  private dailyPlannedHours: number[] = [];  
  // displayPlannedHours: number[]|null = null;

  // public text = {
  //   removeCard: this.I18n.t('js.card.remove_from_list'),
  //   detailsView: this.I18n.t('js.button_open_details'),
  //   baseLineIconAdded: this.I18n.t('js.baseline.icon_tooltip.added'),
  //   baseLineIconChanged: this.I18n.t('js.baseline.icon_tooltip.changed'),
  //   baseLineIconRemoved: this.I18n.t('js.baseline.icon_tooltip.removed'),
  // };
  public text = {
    removeCard: this.I18n.t('js.card.remove_from_list'),
    detailsView: this.I18n.t('js.button_open_details'),
    baseLineIconAdded: this.I18n.t('js.baseline.icon_tooltip.added'),
    baseLineIconChanged: this.I18n.t('js.baseline.icon_tooltip.changed'),
    baseLineIconRemoved: this.I18n.t('js.baseline.icon_tooltip.removed'),
    dailyPlannedHours: this.I18n.t('js.card.daily_planned_hours'),
    plannedHoursButton: this.I18n.t('js.card.planned_hours_button'), // 新增翻译文本
  };
  // js:
  // card:
  //   daily_planned_hours: "Daily Planned Hours"
  //   planned_hours_button: "计划工时"

  public  calcDisplayPlannedHours(): number[]|null {


    console.log('----------------resourceBookingItem =============', this.resourceBookingItem);

    if (this.workPackage?.startDate === null || this.workPackage?.dueDate === null || this.windowStartDate === '' || this.windowEndDate === '') {
      return null;
    }
    console.log('calcDisplayPlannedHours input', this.workPackage.startDate, this.workPackage.dueDate, this.windowStartDate, this.windowEndDate);
    const result = 
        this.calculateTaskVisibility( this.workPackage.startDate, this.workPackage.dueDate, this.windowStartDate, this.windowEndDate);
    if (result) {
      console.log('calcDisplayPlannedHours output', result);
      const { visibleStart, visibleDays, startDayOffset } = result;
      const dailyPlannedHours = this.dailyPlannedHours;
      return  this.getWorkHoursSlice(dailyPlannedHours, startDayOffset, visibleDays);
    }
    return null;
  }

  private getWorkHoursSlice(workHoursArray: number[], startDayOffset: number, visibleDays: number): number[] {
    // 确保 startDayOffset 是有效的索引
    const startIndex = Math.max(0, startDayOffset);
    // 计算结束索引，注意不能超过数组长度
    const endIndex = Math.min(startIndex + visibleDays, workHoursArray.length);
    // 截取数组

    console.log('getWorkHoursSlice params', workHoursArray, startDayOffset, visibleDays);
    return workHoursArray.slice(startIndex, endIndex);
  }

  private calculateTaskVisibility(
    taskStartDate: string,
    taskEndDate: string,
    windowStartDate: string,
    windowEndDate: string
  ): { visibleStart: Date; visibleDays: number; startDayOffset: number } | null {

    const taskStart = new Date(taskStartDate);
    const taskEnd = new Date(taskEndDate);
    const windowStart = new Date(windowStartDate);
    const windowEnd = new Date(windowEndDate);

    let tempDate = windowEnd.getDate();
    // 减少一天  因为输入的时间总是后一天，向前调整一天
    windowEnd.setDate(tempDate - 1);

    const visibleStartRaw = new Date(Math.max(taskStart.getTime(), windowStart.getTime()));
    const visibleEndRaw = new Date(Math.min(taskEnd.getTime(), windowEnd.getTime()));

    if (visibleStartRaw > visibleEndRaw) {
      return null;
    }

    const stripTime = (date: Date) => {
      const d = new Date(date);
      d.setHours(0, 0, 0, 0);
      return d;
    };

    const visibleStartDate = stripTime(visibleStartRaw);
    const visibleEndDate = stripTime(visibleEndRaw);
    const tStartDate = stripTime(taskStart);

    const timeDiff = visibleEndDate.getTime() - visibleStartDate.getTime();
    const visibleDays = Math.floor(timeDiff / (86400 * 1000)) + 1;

    const offsetTime = visibleStartDate.getTime() - tStartDate.getTime();
    const startDayOffset = Math.floor(offsetTime / (86400 * 1000));

    return {
      visibleStart: visibleStartRaw,
      visibleDays,
      startDayOffset
    };
  }

  public showPlannedHours(): void {
  //  alert(`计划工时: ${this.dailyPlannedHours.join(', ')}`);
    console.log(`workpackage=====: ${this.workPackage} ${this.workPackage.assignee.id}`, this.workPackage);
    this.opModalService.show(BookingComponent, this.injector, {
      startDate: this.workPackage.startDate, // 示例开始日期
      endDate: this.workPackage.dueDate,   // 示例结束日期
      totalPlannedHours: this.workPackage.estimatedTime || 8,    // 示例计划工时
      dailyPlannedHours: this.dailyPlannedHours,
      project_id: this.workPackage.project.id,
      assigned_to_id: this.workPackage.assignee.id,
      work_package_id: this.workPackage.id,
      resource_booking_id: this.resourceBookingItem ? this.resourceBookingItem.resource_booking_id : null,
      housrs_per_day: this.resourceBookingItem ? this.resourceBookingItem.hours_per_day : null
    });
  }

  public isNewResource = isNewResource;

  public tooltipPosition = SpotDropAlignmentOption.BottomLeft;

  combinedDateDisplayField = CombinedDateDisplayField;

  constructor(
    readonly pathHelper:PathHelperService,
    readonly I18n:I18nService,
    readonly $state:StateService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly wpTableSelection:WorkPackageViewSelectionService,
    readonly wpTableFocus:WorkPackageViewFocusService,
    readonly cardView:WorkPackageCardViewService,
    readonly cdRef:ChangeDetectorRef,
    readonly timezoneService:TimezoneService,
    readonly schemaCache:SchemaCacheService,
    readonly opModalService:OpModalService,
    readonly injector:Injector,
  ) {
    super();
    // 在构造函数中计算显示时长数组
    // this.displayPlannedHours = this.calcDisplayPlannedHours();
  }

  ngOnInit():void {
    // Update selection state
    combineLatest([
      this.wpTableSelection.live$(),
      this.uiRouterGlobals.params$,
    ])
      .pipe(
        this.untilDestroyed(),
        map(() => {
          if (this.selectedWhenOpen) {
            return this.uiRouterGlobals.params.workPackageId === this.workPackage.id;
          }

          return this.wpTableSelection.isSelected(this.workPackage.id as string);
        }),
      )
      .subscribe((selected) => {
        this.selected = selected;
        this.cdRef.detectChanges();
      });
    
      this.dailyPlannedHours = this.resourceBookingItem ? this.resourceBookingItem.hours : [];
  }

  public classIdentifier(wp:WorkPackageResource):string {
    return this.cardView.classIdentifier(wp);
  }

  public emitStateLinkClicked(event:MouseEvent, wp:WorkPackageResource, detail?:boolean):void {
    if (isClickedWithModifier(event)) {
      return;
    }

    const classIdentifier = this.classIdentifier(wp);
    const stateToEmit = detail ? 'split' : 'show';

    this.wpTableSelection.setSelection(wp.id!, this.cardView.findRenderedCard(classIdentifier));
    this.wpTableFocus.updateFocus(wp.id!);
    this.stateLinkClicked.emit({ workPackageId: wp.id!, requestedState: stateToEmit });
    event.preventDefault();
  }

  public cardClasses():{ [className:string]:boolean } {
    const base = 'op-wp-single-card';

    return {
      [`${base}_selected`]: this.selected,
      [`${base}_draggable`]: this.draggable,
      [`${base}_new`]: isNewResource(this.workPackage),
      [`${base}_shrink`]: this.shrinkOnMobile,
      [`${base}_inline`]: this.showAsInlineCard,
      [`${base}_closed`]: this.isClosed,
      [`${base}_ghosted`]: this.showAsGhost,
      // eslint-disable-next-line @typescript-eslint/restrict-template-expressions
      [`${base}-${this.workPackage.id}`]: !!this.workPackage.id,
      [`${base}_${this.orientation}`]: true,
    };
  }

  cardTitle():string {
    return `${this.workPackage.subject} (${(this.workPackage.status as StatusResource).name})`;
  }

  public baselineIcon(workPackage:WorkPackageResource) {
    this.baselineMode = getBaselineState(workPackage, this.schemaCache);
    return this.baselineMode;
  }

  // eslint-disable-next-line class-methods-use-this
  public wpTypeAttribute(wp:WorkPackageResource):string {
    return wp.type.name;
  }

  // eslint-disable-next-line class-methods-use-this
  public wpSubject(wp:WorkPackageResource):string {
    return wp.subject;
  }

  // eslint-disable-next-line class-methods-use-this
  public wpProjectName(wp:WorkPackageResource):string {
    return wp.project?.name;
  }

  public fullWorkPackageLink(wp:WorkPackageResource):string {
    return this.$state.href('work-packages.show', { workPackageId: wp.id });
  }

  public cardHighlightingClass(wp:WorkPackageResource):string {
    return this.cardHighlighting(wp);
  }

  public typeHighlightingClass(wp:WorkPackageResource):string {
    return this.attributeHighlighting('type', wp);
  }

  public onRemoved(wp:WorkPackageResource):void {
    this.onRemove.emit(wp);
  }

  public cardCoverImageShown(wp:WorkPackageResource):boolean {
    return this.bcfSnapshotPath(wp) !== null;
  }

  // eslint-disable-next-line class-methods-use-this
  public bcfSnapshotPath(wp:WorkPackageResource):string|null {
    return wp.bcfViewpoints && wp.bcfViewpoints.length > 0 ? `${wp.bcfViewpoints[0].href}/snapshot` : null;
  }

  private cardHighlighting(wp:WorkPackageResource):string {
    if (['status', 'priority', 'type'].includes(this.highlightingMode)) {
      return Highlighting.backgroundClass(this.highlightingMode, wp[this.highlightingMode].id);
    }
    return '';
  }

  // eslint-disable-next-line class-methods-use-this
  private attributeHighlighting(type:string, wp:WorkPackageResource):string {
    return Highlighting.inlineClass(type, wp.type.id!);
  }
}
