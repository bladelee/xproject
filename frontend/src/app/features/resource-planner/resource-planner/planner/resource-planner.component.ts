// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2024 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Resource
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  Injector,
  OnDestroy,
  OnInit,
  TemplateRef,
  ViewChild,
} from '@angular/core';
import { CalendarOptions, DateSelectArg, EventApi, EventDropArg, EventInput } from '@fullcalendar/core';
import { BehaviorSubject, combineLatest, Subject } from 'rxjs';
import {
  debounceTime,
  defaultIfEmpty,
  distinctUntilChanged,
  filter,
  finalize,
  map,
  mergeMap,
  shareReplay,
  startWith,
  switchMap,
  take,
  tap,
  withLatestFrom,
} from 'rxjs/operators';
import { StateService } from '@uirouter/angular';
import resourceTimelinePlugin from '@fullcalendar/resource-timeline';
import interactionPlugin, {
  EventDragStartArg,
  EventDragStopArg,
  EventReceiveArg,
  EventResizeDoneArg,
} from '@fullcalendar/interaction';
import { FullCalendarComponent } from '@fullcalendar/angular';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { ApiV3ListFilter, ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { WorkPackageResource, BookingItem } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { MAGIC_PAGE_NUMBER } from 'core-app/core/apiv3/helpers/get-paginated-results';
import { CalendarDragDropService } from 'core-app/features/resource-planner/resource-planner/calendar-drag-drop.service';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import {
  KeepTabService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import {
  resourcePlannerEventAdded,
  resourcePlannerEventRemoved,
  resourcePlannerPageRefresh,
} from 'core-app/features/resource-planner/resource-planner/planner/resource-planner.actions';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { skeletonEvents, skeletonResources } from './loading-skeleton-data';
import { CapabilitiesResourceService } from 'core-app/core/state/capabilities/capabilities.service';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { OpWorkPackagesCalendarService } from 'core-app/features/calendar/op-work-packages-calendar.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { RawOptionsFromRefiners } from '@fullcalendar/core/internal';
import { ViewOptionRefiners } from '@fullcalendar/common';
import { ResourceApi } from '@fullcalendar/resource';
import { DeviceService } from 'core-app/core/browser/device.service';
import { EffectCallback, registerEffectCallbacks } from 'core-app/core/state/effects/effect-handler.decorator';
import {
  addBackgroundEvents,
  removeBackgroundEvents,
} from 'core-app/features/resource-planner/resource-planner/planner/background-events';

import { ResourceBookingService, WorkPackageHours, ResourceBookingResponse, ResourceBookingLoadResponse, WorkLoads, IdMapping } from 'core-app/features/resource-planner/resource-planner/resource-booking/resource-booking.service';

import { firstValueFrom, forkJoin, of } from 'rxjs';
import { catchError} from 'rxjs/operators';

import * as moment from 'moment-timezone';
import allLocales from '@fullcalendar/core/locales-all';

import { debugLog } from 'core-app/shared/helpers/debug_output';
import { IUser } from 'core-app/core/state/principals/user.model';

export type ResourcePlannerViewOptionKey = 'resourceTimelineWorkWeek'|'resourceTimelineWeek'|'resourceTimelineTwoWeeks'|'resourceTimelineFourWeeks'|'resourceTimelineEightWeeks';
export type ResourcePlannerViewOptions = { [K in ResourcePlannerViewOptionKey]:RawOptionsFromRefiners<Required<ViewOptionRefiners>> };


@Component({
  selector: 'op-resource-planner',
  templateUrl: './resource-planner.component.html',
  styleUrls: ['./resource-planner.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ResourcePlannerComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @ViewChild('ucCalendar', { read: ElementRef })
  set ucCalendarElement(v:ElementRef|undefined) {
    this.calendar.resizeObserver(v);
  }

  @ViewChild('resourceContent') resourceContent:TemplateRef<unknown>;

  @ViewChild('assigneeAutocompleter') assigneeAutocompleter:TemplateRef<unknown>;

  @ViewChild('removeDropzone', { read: ElementRef }) removeDropzone:ElementRef;

  @ViewChild('addExistingToggle', { read: ElementRef }) addExistingToggle:ElementRef;

  calendarOptions$ = new Subject<CalendarOptions>();

  draggingItem$ = new BehaviorSubject<EventDragStartArg|undefined>(undefined);

  globalDraggingItem$ = combineLatest([
    this.draggingItem$,
    this.calendarDrag.isDragging$,
  ]).pipe(
    map(([draggingItem, externalDrag]) => {
      if (externalDrag !== undefined) {
        return externalDrag;
      }

      if (draggingItem !== undefined) {
        return (draggingItem.event.extendedProps.workPackage as WorkPackageResource).id as string;
      }

      return undefined;
    }),
  );

  dropzoneHovered$ = new BehaviorSubject<boolean>(false);

  dropzoneAllowed$ = this
    .draggingItem$
    .pipe(
      filter((dragging) => !!dragging),
      map((dragging) => {
        const workPackage = (dragging as EventDragStartArg).event.extendedProps.workPackage as WorkPackageResource;
        const dateEditable = this.workPackagesCalendar.dateEditable(workPackage);
        const resourceEditable = this.eventResourceEditable(workPackage);
        return dateEditable && resourceEditable;
      }),
    );

  dropzone$ = combineLatest([
    this.draggingItem$,
    this.dropzoneHovered$,
    this.dropzoneAllowed$,
  ])
    .pipe(
      map(([dragging, isHovering, canDrop]) => ({ dragging, isHovering, canDrop })),
    );

  projectIdentifier:string|undefined = undefined;

  showAddExistingPane = new BehaviorSubject<boolean>(true);

  showAddAssignee$ = new BehaviorSubject<boolean>(false);

  private principalIds$ = this.wpTableFilters
    .live$()
    .pipe(
        this.untilDestroyed(),
        map((queryFilters) => {
            const assigneeFilter = queryFilters.find((queryFilter) => queryFilter.id === 'assignee');
            return ((assigneeFilter?.values || []) as HalResource[]).map((p) => p.id).filter(id => typeof id === 'string');
        }),
    );

  private assigneeCaps$ = this.wpTableFilters
    .live$()
    .pipe(
      this.untilDestroyed(),
      switchMap((queryFilters) => {
        const filters:ApiV3ListFilter[] = [
          ['action', '=', ['work_packages/assigned']],
        ];
        const assigneeFilter = queryFilters.find((queryFilter) => queryFilter.id === 'assignee');
        if (assigneeFilter) {
          const values = (assigneeFilter.values as HalResource[]).map((el:HalResource) => el.id as string);
          filters.push(['principal', '=', values]);
        }

        const projectFilter = queryFilters.find((queryFilter) => queryFilter.id === 'project');
        if (projectFilter) {
          const values = (projectFilter.values as HalResource[]).map((el:HalResource) => `p${el.id as string}`);
          filters.push(['context', '=', values]);
        } else {
          filters.push(['context', '=', [`p${this.currentProject.id as string}`]]);
        }

        return this
          .capabilitiesResourceService
          .fetchCapabilities({ pageSize: MAGIC_PAGE_NUMBER, filters });
      }),
      map((result) => result
        ._embedded
        .elements
        .reduce(
          (list:{ [projectId:string]:string[] }, cap:ICapability) => {
            const project = cap._links.context.href;
            const principal = cap._links.principal.href;
            const cur = list[project] || [];
            return {
              ...list,
              [project]: [...cur, principal],
            };
          },
          {},
        )),
      startWith({} as { [projectId:string]:string[] }),
      shareReplay(1),
    );

  private params$ = this.principalIds$
    .pipe(
      this.untilDestroyed(),
      filter((ids) => ids.length > 0),
      map((ids) => ({
        filters: [['id', '=', ids]],
        pageSize: MAGIC_PAGE_NUMBER,
      }) as ApiV3ListParameters),
    );

  isEmpty$ = combineLatest([
    this.principalIds$,
    this.showAddAssignee$,
  ]).pipe(
    debounceTime(250),
    map(([principals, showAddAssignee]) => {
      this.loadingIndicatorService.table.stop();
      return !principals.length && !showAddAssignee;
    }),
  );

  private loading$:Subject<unknown>|null = null;

  assignees:HalResource[] = [];

  statuses:StatusResource[] = [];

  image = {
    empty_state: imagePath('resource-planner/empty-state.svg'),
  };

  text = {
    add_existing: this.I18n.t('js.resource_planner.add_existing'),
    add_existing_title: this.I18n.t('js.resource_planner.add_existing_title'),
    assignee: this.I18n.t('js.label_assignee'),
    add_assignee: this.I18n.t('js.resource_planner.add_assignee'),
    remove_assignee: this.I18n.t('js.resource_planner.remove_assignee'),
    noData: this.I18n.t('js.resource_planner.no_data'),
    work_week: this.I18n.t('js.resource_planner.work_week'),
    two_weeks: this.I18n.t('js.resource_planner.two_weeks'),
    one_week: this.I18n.t('js.resource_planner.one_week'),
    four_weeks: this.I18n.t('js.resource_planner.four_weeks'),
    eight_weeks: this.I18n.t('js.resource_planner.eight_weeks'),
    today: this.I18n.t('js.resource_planner.today'),
    drag_here_to_remove: this.I18n.t('js.resource_planner.drag_here_to_remove'),
    cannot_drag_here: this.I18n.t('js.resource_planner.cannot_drag_here'),
    updating: this.I18n.t('js.ajax.updating'),
    successful_update: this.I18n.t('js.notice_successful_update'),
    cannot_drag_to_non_working_day: this.I18n.t('js.resource_planner.cannot_drag_to_non_working_day'),
  };

  principals$ = this.principalIds$
    .pipe(
      this.untilDestroyed(),
      mergeMap((ids:string[]) => this.principalsResourceService.lookupMany(ids)),
      debounceTime(50),
      distinctUntilChanged((prev, curr) => prev.length === curr.length && prev.length === 0),
      shareReplay(1),
    );

  private dateChangeSubject$ = new Subject<[string, string]>();
  private loadData$ = new Subject<{ assigneeId: string, entries: WorkLoads }[]>;

  // private loadData$ = new Subject<{ assigneeId: string, entries: WorkLoads, idMapping: { [workPackageId: string]: BookingItem } }[]>;
  private workPackageToResourceBookingMap: { [workPackageId: string]: BookingItem } = {};
  private loadCache: { [assigneeId: string]: { [date: string]: { entries: WorkLoads } } } = {};

  public cachedStartDate: string = '';
  public cachedEndDate: string = '';

  isMobile = this.deviceService.isMobile;

  private initialCalendarView = this.workPackagesCalendar.initialView || 'resourceTimelineWorkWeek';

  private viewOptionDefaults = {
    type: 'resourceTimeline',
    slotDuration: { days: 1 },
    resourceAreaColumns: [
      // { 
      //   field: 'principal',
      //   headerContent: {
      //     html: `<span class="spot-link spot-link_inactive"><span aria-label="${this.text.assignee}" class="spot-icon spot-icon_user"></span><span class="hidden-for-mobile">${this.text.assignee}</span></span>`,
      //   },
      // },
      {
        // group: true,
        field: 'title',
        headerContent: {
          html: `<span class="spot-link spot-link_inactive"><span aria-label="${this.text.assignee}" class="spot-icon spot-icon_user"></span><span class="hidden-for-mobile">${this.text.assignee}</span></span>`,
        },
      },      
      {
          field: 'contentType',
          headerContent: '类别'
          // headerContent: 'Type'
      }
    ],
  };

  public viewOptions:ResourcePlannerViewOptions = {
    resourceTimelineWorkWeek: {
      ...this.viewOptionDefaults,
      ...{
        duration: { weeks: 1 },
        slotLabelFormat: [
          { weekday: 'long', day: '2-digit' },
        ],
        buttonText: this.text.work_week,
      },
    },
    resourceTimelineWeek: {
      ...this.viewOptionDefaults,
      ...{
        duration: { weeks: 1 },
        slotLabelFormat: [
          { weekday: 'long', day: '2-digit' },
        ],
        buttonText: this.text.one_week,
      },
    },
    resourceTimelineTwoWeeks: {
      ...this.viewOptionDefaults,
      ...{
        buttonText: this.text.two_weeks,
        duration: { weeks: 2 },
        dateIncrement: { weeks: 1 },
        slotLabelFormat: [
          { weekday: 'short', day: '2-digit' },
        ],
      },
    },
    resourceTimelineFourWeeks: {
      ...this.viewOptionDefaults,
      ...{
        buttonText: this.text.four_weeks,
        duration: { weeks: 4 },
        dateIncrement: { weeks: 2 },
        slotLabelFormat: [
          { weekday: 'short', day: '2-digit' },
        ],
      },
    },
    resourceTimelineEightWeeks: {
      ...this.viewOptionDefaults,
      ...{
        buttonText: this.text.eight_weeks,
        duration: { weeks: 8 },
        dateIncrement: { weeks: 4 },
        slotLabelFormat: [
          { weekday: 'short', day: '2-digit' },
        ],
      },
    },
  };

  constructor(
    private $state:StateService,
    private configuration:ConfigurationService,
    private principalsResourceService:PrincipalsResourceService,
    private capabilitiesResourceService:CapabilitiesResourceService,
    private wpTableFilters:WorkPackageViewFiltersService,
    private querySpace:IsolatedQuerySpace,
    private currentProject:CurrentProjectService,
    private I18n:I18nService,
    readonly injector:Injector,
    readonly calendar:OpCalendarService,
    readonly workPackagesCalendar:OpWorkPackagesCalendarService,
    readonly halEditing:HalResourceEditingService,
    readonly halNotification:HalResourceNotificationService,
    readonly schemaCache:SchemaCacheService,
    readonly apiV3Service:ApiV3Service,
    readonly calendarDrag:CalendarDragDropService,
    readonly keepTab:KeepTabService,
    readonly actions$:ActionsService,
    readonly toastService:ToastService,
    readonly loadingIndicatorService:LoadingIndicatorService,
    readonly weekdayService:WeekdayService,
    readonly deviceService:DeviceService,
    readonly resourceBookingService:ResourceBookingService
  ) {
    super();
  }

  ngOnInit():void {
    registerEffectCallbacks(this, this.untilDestroyed());
    this.initializeCalendar();
    this.projectIdentifier = this.currentProject.identifier || undefined;

    this.calendar.resize$
      .pipe(
        this.untilDestroyed(),
        debounceTime(50),         
      )
      .subscribe(() => {
        this.ucCalendar.getApi().updateSize();
      //  //更新起始日期、终止日期  
      //  const currentView = this.ucCalendar.getApi().view;
      //  this.dateChangeSubject$.next([currentView.currentStart.toISOString(), currentView.currentEnd.toISOString()]);         
      });

    this.params$
      .pipe(this.untilDestroyed())
      .subscribe((params) => {
        this.principalsResourceService.requireCollection(params).subscribe();
      });

    combineLatest([
      this.principals$,
      this.showAddAssignee$,
    ])
      .pipe(
        this.untilDestroyed(),
        debounceTime(0),
      )
      .subscribe(([principals, showAddAssignee]) => {
        const api = this.ucCalendar.getApi();

        // This also removes the skeleton resources that are rendered initially
        api.getResources().forEach((resource:ResourceApi) => resource.remove());

        principals.forEach((principal) => {
          const id = principal._links.self.href;
          const id_load = `load-${id}`;

          const position = (principal as IUser).position; 
          api.addResource({
            principal,
            id: id_load,
            title: principal.name,
            // contentType: 'load'
            contentType: '负荷'            
          });
          api.addResource({
            principal,
            id: id,
            title: principal.name,
            // contentType: 'wp'
            contentType: '工作包'
          });          
        });

        if (showAddAssignee) {
          api.addResource({
            principal: null,
            id: 'NEW-1',
            title: '',
            contentType: 'load',
          });
          api.addResource({
            principal: null,
            id: 'NEW',
            title: '',
            contentType: 'wp',
          });          
        }
      });

    // This needs to be done after all the subscribers are set up
    this.showAddAssignee$.next(false);

    this
      .apiV3Service
      .statuses
      .get()
      .pipe(
        take(1),
      )
      .subscribe((collection) => {
        this.statuses = collection.elements;
      });  
    
    // 初始化 loadData$
    this.dateChangeSubject$.subscribe(([fromDate, toDate]) => {
      this.cachedStartDate = fromDate;
      this.cachedEndDate = toDate;
      this.getWorkLoadData(fromDate, toDate);
    });    
    
    // 数据变更时，更新 loadData$等
    this.resourceBookingService.updateBooking$.subscribe((updateBooking) => this.updateFn(updateBooking));
    this.resourceBookingService.newBooking$.subscribe((updateBooking) => this.updateFn(updateBooking));   
  }

  // 设置缓存
  private setToCache(assigneeId: string | null, date: string, data: { entries: WorkLoads, idMapping: { [workPackageId: string]: BookingItem } }): void {
    if (!assigneeId) {
        return;
    }
    if (!this.loadCache[assigneeId]) {
        this.loadCache[assigneeId] = {};
    }
    this.loadCache[assigneeId][date] = { entries: data.entries };

    // 更新 workPackageToResourceBookingMap
    Object.entries(data.idMapping).forEach(([workPackageId, bookingItem]) => {
        this.workPackageToResourceBookingMap[workPackageId] = bookingItem;
    });
}

  // 从缓存中获取数据
  private getFromCache(assigneeId: string | null, date: string): { entries: WorkLoads } | undefined {
    if (!assigneeId) {
        return undefined;
    }
    return this.loadCache[assigneeId]?.[date];
}

  // 清空缓存
  private clearCache(): void {
    this.loadCache = {};
    this.workPackageToResourceBookingMap = {};
  }

  
  private getLoadDataFromCache(datesInRange: string[], validAssigneeIds: string[]): { assigneeId: string, entries: WorkLoads }[] {
    return validAssigneeIds.map(assigneeId => {
      const entries = datesInRange.reduce((acc, date) => {
        const cachedEntry = this.getFromCache(assigneeId, date);
        
        // 确保每个日期都有完整的结构
        acc[date] = {
          planned_h_total: cachedEntry?.entries[date]?.planned_h_total || 0,
          work_packages: cachedEntry?.entries[date]?.work_packages || {}
        };
        
        return acc;
      }, {} as WorkLoads);

      return { assigneeId, entries };
    });
  }  

  private async updateFn(updatedBooking: any): Promise<void> {
    console.log('new or updated Booking:', updatedBooking);
    if (updatedBooking === null) {
        return;
    }

    const bookingItem = { 
        resource_booking_id: updatedBooking.id,
        hours_per_day: updatedBooking.hours_per_day,
        hours: updatedBooking.hours
    };

    const assigneeId = updatedBooking.assigned_to_id;
    // 添加非空检查
    if (!assigneeId) {
        return;
    }
    const workPackageId = updatedBooking.work_package_id;
    const startDate = moment(updatedBooking.start_date);
    const endDate = moment(updatedBooking.end_date);
    const hours = updatedBooking.hours;

    // 动态生成与hours长度匹配的datesInRange
    const datesInRange: string[] = [];
    let currentDate = startDate.clone();
    
    // 根据hours数组长度生成日期范围
    for (let i = 0; i < hours.length; i++) {
      // 确保不超过endDate
      if (currentDate > endDate) break;
      
      datesInRange.push(currentDate.format('YYYY-MM-DD'));
      currentDate.add(1, 'day');
    }

    // 确保缓存结构存在
    if (!this.loadCache[assigneeId]) {
      this.loadCache[assigneeId] = {};
    }

    // 更新缓存数据
    datesInRange.forEach((dateStr, index) => {
      if (!this.loadCache[assigneeId][dateStr]) {
        this.loadCache[assigneeId][dateStr] = {
          entries: {
            [dateStr]: {
              planned_h_total: 0,
              work_packages: {
                [workPackageId]: { planned_h: hours[index] }
              }
            }
          }
        };
      }

      // 更新 work_packages 中指定 workPackageId 的 planned_h 字段
      this.loadCache[assigneeId][dateStr].entries[dateStr].work_packages[workPackageId] = { planned_h: hours[index] };

      // 重新计算 planned_h_total
      const workPackages = this.loadCache[assigneeId][dateStr].entries[dateStr].work_packages;
      const planned_h_total = Object.values(workPackages).reduce((total, wp) => total + wp.planned_h, 0);
      this.loadCache[assigneeId][dateStr].entries[dateStr].planned_h_total = planned_h_total;
    });

    // 获取缓存数据（参数调整为动态生成的datesInRange）
    const assigneeIds = await this.getAssigneeIds();
    if (assigneeIds.length === 0) {
        debugLog('No assignees found, skipping workload fetch.');
        return;
    }
    // 2. 过滤无效 ID
    const validAssigneeIds = assigneeIds.filter(id => typeof id === 'string')  as string[];;
    if (validAssigneeIds.length === 0) {
        debugLog('All assignee IDs are invalid.');
        return;
    }
    const loadData = this.getLoadDataFromCache(datesInRange, validAssigneeIds);

    // 更新全局映射
    this.workPackageToResourceBookingMap[workPackageId] = bookingItem;

    console.log('------xxxxx---------------new or update loadData:', loadData);

    // 触发更新
    this.loadData$.next(loadData);
    this.ucCalendar.getApi().refetchEvents();
  }


  ngOnDestroy():void {
    super.ngOnDestroy();
    this.calendar.resizeObs?.disconnect();
    this.clearCache(); // 清空缓存
  }

  private initializeCalendar() {
    void this.weekdayService.loadWeekdays()
      .toPromise()
      .then(() => {
        this.calendarOptions$.next(
          this.workPackagesCalendar.calendarOptions({
            locales: allLocales,
            locale: this.I18n.locale,
            schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
            selectable: true,
            plugins: [resourceTimelinePlugin, interactionPlugin],
            titleFormat: { year: 'numeric', month: 'long', day: 'numeric' },
            initialView: this.initialCalendarView,
            datesSet: (info) => {
              console.log("new datesSet: ", info);
              this.dateChangeSubject$.next([info.startStr, info.endStr]);
            },
            // resourceGroupField: 'position',            
            headerToolbar: {
              left: '',
              center: 'title',
              right: 'prev,next today',
            },
            views: _.merge(
              {},
              this.viewOptions,
              {
                resourceTimelineWorkWeek: {
                  hiddenDays: this.weekdayService.nonWorkingDays.map((weekday) => weekday.day % 7), // The OP days are 1 based but this needs to be 0 based.
                },
              },
            ),
            // Ensure we show the skeleton from the beginning
            progressiveEventRendering: true,
            eventSources: [
              {
                id: 'skeleton',
                events: skeletonEvents,
                editable: false,
              },
              {
                id: 'work_packages',
                events: this.calendarEventsFunction.bind(this) as unknown,
              },
              {
                id: 'load',
                // display: 'background',
                // interactive: false, // 禁止交互                
                // editable: false,           
                // color: 'green',
                // textColor: 'black',
                // display: 'background',
                // editable: false,                
                // events: [{    id: "load-/api/v3/work_packages/7-/api/v3/users/4",  resourceId: "load-/api/v3/users/4", start: "2025-02-17", end: "2025-02-17",  title: "888888888"}],
                events: this.loadEventsFunction.bind(this) as unknown,
              },              
              {
                events: [],
                id: 'background',
                color: 'red',
                textColor: 'white',
                display: 'background',
                editable: false,
              },
            ],
            resources: skeletonResources,
            resourceAreaWidth: this.isMobile ? '60px' : '180px',
            resourceOrder: 'title',
            // selectable: false,
            select: this.handleDateClicked.bind(this) as unknown,
            // DnD configuration
            editable: true,
            droppable: true,
            eventResize: (resizeInfo:EventResizeDoneArg) => {
              const due = moment(resizeInfo.event.endStr).subtract(1, 'day').toDate();
              const start = moment(resizeInfo.event.startStr).toDate();
              const wp = resizeInfo.event.extendedProps.workPackage as WorkPackageResource;
              if (!wp.ignoreNonWorkingDays && (this.weekdayService.isNonWorkingDay(start) || this.weekdayService.isNonWorkingDay(due)
              || this.workPackagesCalendar.isNonWorkingDay(start)|| this.workPackagesCalendar.isNonWorkingDay(due))) {
                this.toastService.addError(this.text.cannot_drag_to_non_working_day);
                resizeInfo?.revert();
                return;
              }
              void this.updateEvent(resizeInfo, false);
            },
            eventResizeStart: (resizeInfo:EventResizeDoneArg) => {
              const wp = resizeInfo.event.extendedProps.workPackage as WorkPackageResource;
              if (!wp.ignoreNonWorkingDays) {
                this.addBackgroundEventsForNonWorkingDays();
              }
            },
            eventResizeStop: () => removeBackgroundEvents(this.ucCalendar.getApi()),
            eventDragStart: (dragInfo:EventDragStartArg) => {
              if (dragInfo.event.source?.id === 'skeleton') {
                return;
              }

              const { el } = dragInfo;
              el.style.pointerEvents = 'none';
              this.draggingItem$.next(dragInfo);
              this.addBackgroundEvents(dragInfo.event);
            },
            eventDragStop: (dragInfo:EventDragStopArg) => {
              const { el } = dragInfo;
              el.style.removeProperty('pointer-events');
              this.draggingItem$.next(undefined);
              removeBackgroundEvents(this.ucCalendar.getApi());
            },
            eventDrop: (dropInfo:EventDropArg) => {
              const start = moment(dropInfo.event.startStr).toDate();
              const wp = dropInfo.event.extendedProps.workPackage as WorkPackageResource;
              if (!wp.ignoreNonWorkingDays && (this.weekdayService.isNonWorkingDay(start) || this.workPackagesCalendar.isNonWorkingDay(start))) {
                this.toastService.addError(this.text.cannot_drag_to_non_working_day);
                dropInfo?.revert();
                return;
              }
              void this.updateEvent(dropInfo, true);
            },
            eventReceive: async (dropInfo:EventReceiveArg) => {
              const start = moment(dropInfo.event.startStr).toDate();
              const wp = dropInfo.event.extendedProps.workPackage as WorkPackageResource;
              if (!wp.ignoreNonWorkingDays && (this.weekdayService.isNonWorkingDay(start) || this.workPackagesCalendar.isNonWorkingDay(start))) {
                this.toastService.addError(this.text.cannot_drag_to_non_working_day);
                dropInfo?.revert();
                return;
              }
              await this.updateEvent(dropInfo, true);
              this.actions$.dispatch(resourcePlannerEventAdded({ workPackage: wp.id as string }));
            },
          } as CalendarOptions),
        );
      });
  }

  // 假设在某个方法中使用了 work_loads
  private processWorkLoads(response: ResourceBookingLoadResponse) {
    response.forEach(userWorkLoads => {
      const { user_id, work_loads } = userWorkLoads;
      // 处理 work_loads 数据
      for (const date in work_loads) {
        const { planned_h_total, work_packages } = work_loads[date];
        // 处理具体日期的数据
        // console.log(`User ID: ${user_id}, Date: ${date}, Planned Hours Total: ${planned_h_total}`);
        for (const workPackageId in work_packages) {
          const { planned_h } = work_packages[workPackageId];
          // console.log(`Work Package ID: ${workPackageId}, Planned Hours: ${planned_h}`);
        }
      }
    });
  }

// 示例调用
private async bookingInit(): Promise<void> {
  try {
    const resourceBooking = await this.resourceBookingService.getResourceBooking(5);
    if (resourceBooking) {
      // console.log('Resource Booking:', resourceBooking);
    }
  } catch (error) {
    console.error('Error in bookingInit:', error);
  }
}


  public getResouceBookingItemByWP(workPackage:WorkPackageResource): BookingItem | null {
    // 确保 workPackageId 是一个有效的字符串
    if (!workPackage || !workPackage.id) {
      debugLog('Invalid workPackageId');
      return null;
    }

    const bookingItem = this.getResourceBookingIdByWorkPackageId(Number(workPackage.id));
    if (!bookingItem) {
      debugLog('bookingItem = undefined');
      return null;
    }    

    // console.log('-----xxxxxxxxxxx--------------getResourceBookingIdByWorkPackageId', bookingItem);
    return bookingItem;
  }   


  
  private async getWorkLoadData(dateFrom: string, dateTo: string): Promise<void> {
    try {
        const assigneeIds = await this.getAssigneeIds();
        if (assigneeIds.length === 0) {
            debugLog('No assignees found, skipping workload fetch.');
            return;
        }
        // 2. 过滤无效 ID
        const validAssigneeIds = assigneeIds.filter(id => typeof id === 'string') as string[];
        if (validAssigneeIds.length === 0) {
            debugLog('All assignee IDs are invalid.');
            return;
        }
        debugLog(`Fetching workload data for ${validAssigneeIds.length} assignees...`);

        // 3. 获取日期范围内的所有日期
        const datesInRange = this.getDatesInRange(dateFrom, dateTo);

        // 4. 初始化缓存结构
        validAssigneeIds.forEach(assigneeId => {
            if (!assigneeId)
               return; 
            if (!this.loadCache[assigneeId]) {
                this.loadCache[assigneeId] = {};
            }
            datesInRange.forEach(date => {
                if (!this.loadCache[assigneeId][date]) {
                    this.loadCache[assigneeId][date] = {
                        entries: {
                            [date]: {
                                planned_h_total: 0,
                                work_packages: {}
                            }
                        }
                    };
                }
            });
        });

        // 5. 并行请求数据并更新缓存
        await this.fetchAndCacheWorkLoadData(validAssigneeIds as string[], datesInRange);

        // 6. 更新状态
        const loadData = this.getLoadDataFromCache(datesInRange, validAssigneeIds as string[]);
        this.loadData$.next(loadData);
        this.ucCalendar.getApi().refetchEvents();
    } catch (error) {
        console.error('Failed to load work package data:', error);
        this.toastService.addError(this.I18n.t('js.resource_planner.load_data_error'));
    }
}

  private async getAssigneeIds() {
    debugLog('Fetching assignee IDs...');

    // 过滤掉非字符串类型的ID
    const assigneeIds = await firstValueFrom(
      this.principalIds$.pipe(
        tap((ids) => debugLog(`Assignee IDs: ${ids}`)),
        take(1),
        filter((ids) => Array.isArray(ids) && ids.length > 0), // 确保是数组且有元素
        map(ids => ids.filter(id => typeof id === 'string')), // 过滤非字符串类型
        defaultIfEmpty([])
      )
    );
    return assigneeIds;
  }

private async fetchAndCacheWorkLoadData(assigneeIds: string[], datesInRange: string[]): Promise<void> {
    const userIds = assigneeIds.map(Number).filter(userId => !isNaN(userId));
    if (userIds.length === 0) {
        return;
    }

    try {
        const response = await firstValueFrom(
            this.resourceBookingService.getUserWorkLoads(userIds, datesInRange[0], datesInRange[datesInRange.length - 1])
        );

        response.forEach(userWorkLoads => {
            const assigneeId = userWorkLoads.user_id.toString();
            const idMapping = userWorkLoads.id_mappings?.reduce((acc, mapping: IdMapping) => ({
                ...acc,
                [mapping.work_package_id]: {
                    resource_booking_id: mapping.resource_booking_id,
                    hours_per_day: mapping.hours_per_day,
                    hours: mapping.hours
                }
            }), {}) || {};

            const entries = userWorkLoads.work_loads || {};
            // datesInRange.forEach(date => {
            //     // 确保 entries[date] 是 WorkLoads 的正确结构
            //     const entry = entries[date] || { 
            //         planned_h_total: 0, 
            //         work_packages: {} 
            //     };
            //     // 保留现有数据，只更新变化的部分
            //     const existingEntry = this.loadCache[assigneeId]?.[date]?.entries[date] || {};
            //     this.loadCache[assigneeId][date] = { 
            //         entries: { 
            //             [date]: {
            //                 ...existingEntry,
            //                 ...entry
            //             }
            //         }
            //     };
            datesInRange.forEach(date => {
              // 确保 entries[date] 是 WorkLoads 的正确结构
              const entry = entries[date] || { 
                planned_h_total: 0, 
                work_packages: {} 
              };
              this.setToCache(assigneeId, date, { 
                entries: { [date]: entry }, // 明确构建符合 WorkLoads 类型的结构
                idMapping 
              });                
                
                
            });
        });
        console.log('----------------------loadCache-----------------------------', this.loadCache);
    } catch (error) {
        console.error(`Error fetching data for assigneeIds ${assigneeIds}:`, error);
    }
}

// 获取日期范围内的所有日期
private getDatesInRange(dateFrom: string, dateTo: string): string[] {
    const dates: string[] = [];
    let currentDate = moment(dateFrom);

    while (currentDate <= moment(dateTo)) {
      dates.push(currentDate.format('YYYY-MM-DD'));
      currentDate.add(1, 'day');
    }

    return dates;
  }


  // 辅助方法：更新资源预订映射
  private updateResourceBookingMap(loadData: any[]) {
    loadData.forEach((data) => {
      Object.entries(data.entries).forEach(([date, entry]) => {
        const workloads = (entry as any).work_packages || {};
        Object.keys(workloads).forEach((wpId) => {
          const mapping = data.idMapping[wpId];
          if (mapping) {
            this.workPackageToResourceBookingMap[wpId] = mapping;
          }
        });
      });
    });
  }


  // 提供查询方法
  public getResourceBookingIdByWorkPackageId(workPackageId: number): BookingItem | undefined {
    // console.log('===========workPackageToResourceBookingMap', this.workPackageToResourceBookingMap)
    return this.workPackageToResourceBookingMap[workPackageId];
  }

  public async loadEventsFunction(
    fetchInfo: { start: Date, end: Date, timeZone: string },
    successCallback: (events: EventInput[]) => void,
    failureCallback: (error: unknown) => void,
  ): Promise<void> {
    debugLog('load events Func called');

    // try {
    //   debugLog('Subscribing to loadData$');
    return new Promise((resolve, reject) =>{
      this.loadData$
        .pipe(
          tap(() => debugLog('start taking loadData$')),
          take(1), // 只取最新的一个数据
          // debounceTime(100),
          tap((loadData) => debugLog('taked loadData$', loadData)), // 添加调试信息
          finalize(() => this.clearLoading())
          // catchError((error) => {
          //   failureCallback(error);
          //   this.toastService.addError(this.I18n.t('js.resource_planner.load_data_error'));
          //   return of([]); // 返回空数组以避免后续处理
          // })
        )
        .subscribe(
          (loadData) => {
            debugLog('loadData$ emitted', loadData);
            // 使用 loadData 进行映射
            const events = loadData.reduce((acc: EventInput[], { assigneeId, entries }) => {
              debugLog('Processing assigneeId:', assigneeId, acc, entries);
              // 确保 entries 是 WorkLoads 类型
              if (typeof entries === 'object' && !Array.isArray(entries) && entries !== null) {
                for (const date in entries) {
                  if (entries.hasOwnProperty(date)) {
                    const { planned_h_total, work_packages } = entries[date] as { planned_h_total: number, work_packages: { [workPackageId: string]: WorkPackageHours } };
                    acc.push({
                      id: `load-${assigneeId}-${date}`,
                      resourceId: `load-/api/v3/users/${assigneeId}`, // 对应负载资源行
                      start: date,
                      end: date,
                      title: `${planned_h_total}h`, // 显示小时数
                      display: 'background',
                      color: this.getLoadColor(planned_h_total),
                      extendedProps: {
                        type: 'load',
                        totalHours: planned_h_total
                      }
                    });
                  }
                }
              }
              return acc;
            }, []);

            debugLog('loaded events', events);
            successCallback(events);
            // this.ucCalendar.getApi().render();
            resolve()
          },
          ()=> {
            debugLog('loadData$ error');
            failureCallback(undefined);
            reject();
          }
        );
      })
  }


  // 颜色映射逻辑（示例）
  private getLoadColor(hours: number): string {
    const MAX_DAILY_CAPACITY = 8; // 假设每日最大8小时
    const ratio = hours / MAX_DAILY_CAPACITY;
    
    if (ratio >= 1) return '#ff4444';    // 超负荷
    if (ratio >= 0.8) return '#ffb347';  // 高负荷
    return '#77dd77';                    // 正常
  }  


  public async calendarEventsFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):Promise<void> {

    // this.dateChangeSubject$.next([fetchInfo.start.toISOString(), fetchInfo.end.toISOString()]);  
    debugLog('events Func called');
    await this.workPackagesCalendar.updateTimeframe(fetchInfo, this.projectIdentifier);

    this
      .workPackagesCalendar
      .currentWorkPackages$
      .pipe(
        withLatestFrom(this.assigneeCaps$),
        take(1),
        finalize(() => this.clearLoading()),
      )
      .subscribe(
        ([workPackages, projectAssignables]) => {
          const events = this.mapToCalendarEvents(workPackages.elements, projectAssignables);
          debugLog('events', events);
          this.workPackagesCalendar.warnOnTooManyResults(workPackages);

          this.removeExternalEvents();

          successCallback(events);

          this.ucCalendar.getApi().render();
        },
        failureCallback,
      );
  }

  public switchView(key:ResourcePlannerViewOptionKey):void {
    this.ucCalendar.getApi().changeView(key);
  }

  public get currentViewTitle():string {
    return this.viewOptions[((this.ucCalendar && this.ucCalendar.getApi().view.type) || this.initialCalendarView) as ResourcePlannerViewOptionKey].buttonText as string;
  }

  /**
   * Clear loading and show successful toast if we were reloading the page
   * @private
   */
  private clearLoading():void {
    const prevLoading = this.loading$;
    if (!prevLoading) {
      return;
    }

    this.loading$ = null;
    setTimeout(() => {
      prevLoading.complete();
      this.toastService.addSuccess(this.text.successful_update);
    }, 500);
  }

  isDraggedEvent(id:string):boolean {
    const dragging = this.draggingItem$.getValue();
    return !!dragging && (dragging.event.extendedProps?.workPackage as undefined|WorkPackageResource)?.href === id;
  }

  public showAssigneeAddRow():void {
    this.showAddAssignee$.next(true);
    this.ucCalendar.getApi().refetchEvents();
  }

  public addAssignee(principal:HalResource):void {
    this.showAddAssignee$.next(false);

    const modifyFilter = (assigneeFilter:QueryFilterInstanceResource) => {
      // eslint-disable-next-line no-param-reassign
      assigneeFilter.values = [
        ...assigneeFilter.values as HalResource[],
        principal,
      ];
    };

    if (this.wpTableFilters.findIndex('assignee') === -1) {
      // Replace actually also instantiates if it does not exist, which is handy here
      this.wpTableFilters.replace('assignee', modifyFilter.bind(this));
    } else {
      this.wpTableFilters.modify('assignee', modifyFilter.bind(this));
    }
  }

  public removeAssignee(href:string):void {
    const numberOfAssignees = this.wpTableFilters.find('assignee')?.values?.length;
    if (numberOfAssignees && numberOfAssignees <= 1) {
      this.wpTableFilters.remove('assignee');
    } else {
      this.wpTableFilters.modify('assignee', (assigneeFilter:QueryFilterInstanceResource) => {
        // eslint-disable-next-line no-param-reassign
        assigneeFilter.values = (assigneeFilter.values as HalResource[])
          .filter((filterValue) => filterValue.href !== href);
      });
    }
  }

  isWpEndDateInCurrentView(workPackage:WorkPackageResource):boolean {
    const { dueDate } = workPackage;

    if (!dueDate) {
      return !!workPackage.date;
    }

    const viewEndDate = this.ucCalendar.getApi().view.currentEnd.setHours(0, 0, 0, 0);
    const dateToCheck = new Date(dueDate).setHours(0, 0, 0, 0);

    return dateToCheck < viewEndDate;
  }

  isWpStartDateInCurrentView(workPackage:WorkPackageResource):boolean {
    const { startDate } = workPackage;

    if (!startDate) {
      return !!workPackage.date;
    }

    const viewStartDate = this.ucCalendar.getApi().view.currentStart.setHours(0, 0, 0, 0);
    const dateToCheck = new Date(startDate).setHours(0, 0, 0, 0);

    return dateToCheck >= viewStartDate;
  }

  showDisabledText(workPackage:WorkPackageResource):{ text:string, orientation:'left'|'right' } {
    const dueDate = new Date(workPackage.dueDate).setHours(0, 0, 0, 0);
    const firstCalendarDay = this.ucCalendar.getApi().view.currentStart.setHours(0, 0, 0, 0);
    return {
      text: this.calendarDrag.workPackageDisabledExplanation(workPackage),
      orientation: dueDate === firstCalendarDay ? 'right' : 'left',
    };
  }

  isStatusClosed(workPackage:WorkPackageResource):boolean {
    const status = this.statuses.find((el) => el.id === (workPackage.status as StatusResource).id);

    return status ? status.isClosed : false;
  }

  public async removeEvent(item:EventDragStartArg):Promise<void> {
    // Remove item from view
    item.el.remove();
    item.event.remove();

    const workPackage = item.event.extendedProps.workPackage as WorkPackageResource;
    const changeset = this.halEditing.edit(workPackage);
    changeset.setValue('assignee', { href: null });
    changeset.setValue('startDate', null);
    changeset.setValue('dueDate', null);

    await this.saveChangeset(changeset);

    this.actions$.dispatch(resourcePlannerEventRemoved({ workPackage: workPackage.id as string }));
  }

  private mapToCalendarEvents(
    workPackages:WorkPackageResource[],
    projectAssignables:{ [projectId:string]:string[] },
  ):EventInput[] {
    return workPackages
      .map((workPackage:WorkPackageResource):EventInput|undefined => {
        if (!workPackage.assignee) {
          return undefined;
        }

        const assignee = this.wpAssignee(workPackage);
        const durationEditable = this.workPackagesCalendar.eventDurationEditable(workPackage);
        const resourceEditable = this.eventResourceEditable(workPackage);

        return {
          id: `${workPackage.href as string}-${assignee}`,
          resourceId: assignee,
          editable: durationEditable || resourceEditable,
          durationEditable,
          resourceEditable,
          constraint: this.eventConstraints(workPackage, projectAssignables),
          title: workPackage.subject,
          start: this.wpStartDate(workPackage),
          end: this.wpEndDate(workPackage),
          backgroundColor: '#FFFFFF',
          borderColor: '#FFFFFF',
          allDay: true,
          workPackage,
        };
      })
      .filter((event) => !!event) as EventInput[];
  }

  private handleDateClicked(info:DateSelectArg) {

    debugLog('Date clicked', info);
    const due = moment(info.endStr).subtract(1, 'day').toDate();
    const nonWorkingDays = this.weekdayService.isNonWorkingDay(info.start) || this.weekdayService.isNonWorkingDay(due);

    if (info.resource?.id.startsWith('load')) {
      return;
    }

    this.openNewSplitCreate(
      info.startStr,
      // end date is exclusive
      this.workPackagesCalendar.getEndDateFromTimestamp(info.endStr),
      info.resource?.id || '',
      nonWorkingDays,
    );
  }

  // Allow triggering the select from a event, as
  // this is otherwise not testable from selenium
  @HostListener(
    'document:resourcePlannerSelectDate',
    ['$event.detail.start', '$event.detail.end', '$event.detail.assignee'],
  )
  openNewSplitCreate(start:string, end:string, resourceHref:string, nonWorkingDays:boolean):void {
    const defaults = {
      startDate: start,
      dueDate: end,
      _links: {
        assignee: {
          href: resourceHref,
        },
      },
      ignoreNonWorkingDays: nonWorkingDays,
    };

    void this.$state.go(
      splitViewRoute(this.$state, 'new'),
      {
        defaults,
        tabIdentifier: 'overview',
      },
    );
  }

  openStateLink(event:{ workPackageId:string; requestedState:string }):void {
    const params = { workPackageId: event.workPackageId };

    if (event.requestedState === 'split') {
      this.keepTab.goCurrentDetailsState(params);
    } else {
      this.keepTab.goCurrentShowState(params);
    }
  }

  shouldShowAsGhost(id:string, globalDraggingId:string|undefined):boolean {
    if (globalDraggingId === undefined) {
      return false;
    }

    // Everything else except the currently dragged element should be shown as ghost.
    return id !== globalDraggingId;
  }

  private async updateEvent(info:EventResizeDoneArg|EventDropArg|EventReceiveArg, dragged:boolean):Promise<void> {
    const changeset = this.workPackagesCalendar.updateDates(info, dragged);
    const resource = info.event.getResources()[0];
    if (resource) {
      changeset.setValue('assignee', { href: resource.id });
    }

    this.calendarDrag.handleDrop(changeset.projectedResource);
    await this.saveChangeset(changeset, info);
  }

  private async saveChangeset(changeset:ResourceChangeset<WorkPackageResource>, info?:EventResizeDoneArg|EventDropArg|EventReceiveArg) {
    try {
      this.loading$ = new Subject<unknown>();
      this.toastService.addLoading(this.loading$);
      await this.halEditing.save(changeset);
    } catch (e:unknown) {
      this.loading$?.complete();
      this.halNotification.showError((e as HalError).resource, changeset.projectedResource);
      this.calendarDrag.handleDropError(changeset.projectedResource);
      info?.revert();
    }
  }

  private eventResourceEditable(wp:WorkPackageResource):boolean {
    const schema = this.schemaCache.of(wp);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return !!schema.assignee?.writable && schema.isAttributeEditable('assignee');
  }

  // Todo: Evaluate whether we really want to use that from a UI perspective ¯\_(ツ)_/¯
  // When users have the right to change the assignee but cannot change the date (due to hierarchy for example),
  // they are forced to drag the wp to the exact same date in the others assignee row. This might be confusing.
  // Without these constraints however, users can drag the WP everywhere, thinking that they changed the date as well.
  // The WP then moves back to the original date when the calendar re-draws again. Also not optimal..
  private eventConstraints(
    wp:WorkPackageResource,
    projectAssignables:{ [projectId:string]:string[] },
  ):{ [key:string]:string|string[] } {
    const constraints:{ [key:string]:string|string[] } = {};

    if (!this.workPackagesCalendar.eventDurationEditable(wp) && !wp.date) {
      constraints.start = this.wpStartDate(wp);
      constraints.end = this.wpEndDate(wp);
    }

    if (!this.eventResourceEditable(wp)) {
      constraints.resourceIds = [this.wpAssignee(wp)];
      return constraints;
    }

    const assignables = projectAssignables[(wp.project as HalResource).href as string];
    if (assignables) {
      constraints.resourceIds = [...assignables];
    }

    return constraints;
  }

  private wpStartDate(wp:WorkPackageResource):string {
    return this.workPackagesCalendar.eventDate(wp, 'start');
  }

  private wpEndDate(wp:WorkPackageResource):string {
    const endDate = this.workPackagesCalendar.eventDate(wp, 'due');
    return moment(endDate).add(1, 'days').format('YYYY-MM-DD');
  }

  private wpAssignee(wp:WorkPackageResource):string {
    return (wp.assignee as HalResource).href as string;
  }

  private toggleAddExistingPane():void {
    this.showAddExistingPane.next(!this.showAddExistingPane.getValue());
    (this.addExistingToggle.nativeElement as HTMLElement).blur();
  }

  private removeExternalEvents():void {
    this
      .ucCalendar
      .getApi()
      .getEvents()
      .forEach((evt) => {
        if (evt.id.includes('external')) {
          evt.remove();
        }
      });
  }

  private addBackgroundEvents(event:EventApi) {
    const wp = event.extendedProps.workPackage as WorkPackageResource;

    this
      .assigneeCaps$
      .pipe(
        filter((el) => Object.keys(el).length > 0),
        take(1),
        map((projectAssignables) => projectAssignables[(wp.project as HalResource).href as string]),
        withLatestFrom(this.principals$),
      )
      .subscribe(([assignable, principals]) => {
        const api = this.ucCalendar.getApi();
        if (!wp.ignoreNonWorkingDays) {
          this.addBackgroundEventsForNonWorkingDays();
        }
        const eventBase = {
          start: moment().subtract('1', 'month').toDate(),
          end: moment().add('1', 'month').toDate(),
        };

        principals.forEach((principal) => {
          const resourceId = principal._links.self.href;

          if (!assignable || !assignable.includes(resourceId)) {
            api.addEvent({ ...eventBase, resourceId }, 'background');
          }
        });
      });
  }

  private addBackgroundEventsForNonWorkingDays() {
    addBackgroundEvents(
      this.ucCalendar.getApi(),
      (date) => this.weekdayService.isNonWorkingDay(date)|| this.workPackagesCalendar.isNonWorkingDay(date),
    );
  }

  @EffectCallback(resourcePlannerPageRefresh)
  reloadOnEventAdded(action:ReturnType<typeof resourcePlannerPageRefresh>):void {
    if (action.showLoading) {
      this.loading$ = new Subject<unknown>();
      this.toastService.addLoading(this.loading$);
    }

    this.ucCalendar.getApi().refetchEvents();
  }
}
