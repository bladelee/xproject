// Import and register all your controllers from the importmap under controllers/*

import { application } from "./application"
import DepartmentSelectorController from "./department_selector_controller.js"
import ProjectSelectorController from "./project_selector_controller.js"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

application.register("department-selector", DepartmentSelectorController)
application.register("project-selector", ProjectSelectorController) 