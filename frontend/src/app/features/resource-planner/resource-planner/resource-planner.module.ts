import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UIRouterModule } from '@uirouter/angular';
import { DynamicModule } from 'ng-dynamic-component';
import { FullCalendarModule } from '@fullcalendar/angular';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { RESOURCE_PLANNER_ROUTES } from 'core-app/features/resource-planner/resource-planner/resource-planner.routes';
import { ResourcePlannerComponent } from 'core-app/features/resource-planner/resource-planner/planner/resource-planner.component';
import { AddAssigneeComponent } from 'core-app/features/resource-planner/resource-planner/assignee/add-assignee.component';
import { ResourcePlannerPageComponent } from 'core-app/features/resource-planner/resource-planner/page/resource-planner-page.component';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { AddExistingPaneComponent } from './add-work-packages/add-existing-pane.component';
import { OpenprojectContentLoaderModule } from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { ResourcePlannerSidemenuComponent } from 'core-app/features/resource-planner/resource-planner/sidemenu/resource-planner-sidemenu.component';
import { ResourcePlannerViewSelectMenuDirective } from 'core-app/features/resource-planner/resource-planner/view-select/view-select-menu.directive';

@NgModule({
  declarations: [
    ResourcePlannerComponent,
    ResourcePlannerPageComponent,
    AddAssigneeComponent,
    AddExistingPaneComponent,
    ResourcePlannerSidemenuComponent,
    ResourcePlannerViewSelectMenuDirective,
  ],
  imports: [
    OpSharedModule,
    // Routes for /resource_planner
    UIRouterModule.forChild({
      states: RESOURCE_PLANNER_ROUTES,
    }),
    DynamicModule,
    CommonModule,
    IconModule,
    OpenprojectPrincipalRenderingModule,
    OpenprojectWorkPackagesModule,
    FullCalendarModule,
    // Autocompleters
    OpenprojectAutocompleterModule,
    OpenprojectContentLoaderModule,
  ],
})
export class ResourcePlannerModule {}
