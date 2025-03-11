import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostBinding,
  Input,
} from '@angular/core';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { map } from 'rxjs/operators';

export const opResourcePlannerSidemenuSelector = 'op-resource-planner-sidemenu';

@Component({
  selector: opResourcePlannerSidemenuSelector,
  templateUrl: './resource-planner-sidemenu.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ResourcePlannerSidemenuComponent extends UntilDestroyedMixin {
  @HostBinding('class.op-sidebar') className = true;

  @Input() menuItems:string[] = [];

  @Input() projectId:string|undefined;

  canAddResourcePlanner$ = this
    .currentUserService
    .hasCapabilities$(
      'resource_planners/create',
      this.currentProjectService.id || null,
    )
    .pipe(
      map((val) => val && !this.bannersService.eeShowBanners),
    );

  createButton = {
    text: this.I18n.t('js.resource_planner.create_label'),
    title: this.I18n.t('js.resource_planner.create_title'),
    uiSref: 'resource_planner.page.show',
    uiParams: {
      query_id: null,
      query_props: '',
    },
  };

  constructor(
    readonly elementRef:ElementRef,
    readonly currentUserService:CurrentUserService,
    readonly currentProjectService:CurrentProjectService,
    readonly bannersService:BannersService,
    readonly I18n:I18nService,
  ) {
    super();

    populateInputsFromDataset(this);
  }
}
