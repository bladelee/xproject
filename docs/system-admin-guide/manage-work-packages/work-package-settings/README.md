---
sidebar_navigation:
  title: Settings
  priority: 999
description: Work package settings in OpenProject.
keywords: work package settings, work package configuration
---
# Work package settings

To change basic settings for work package tracking in OpenProject, navigate to **Administration → Work packages → Settings**.

You can adjust the following:

1. **Allow cross-project work package relations**, i.e. that work packages created in one project can have relations to work packages in another project, for example parent-children work packages.

2. **Display subprojects work packages in main projects** by default. This way the work packages of subprojects will always be visible in the main project if a user has the corresponding role in the subproject to see work packages.

3. **Use current date as start date for new work packages**. This way the current date will always be set as a start date if your create new work packages. Also, if you copy projects, the new work packages will get the current date as start date.

4. **Progress calculation** lets you pick between two modes for how the **%&nsbp;Complete** field is calculated for work packages.
	- **Work-based**: %&nbsp;Complete is automatically calculated based on Work and Remaining work values for that work package, both of which are then necessary to have a value for %&nbsp;Complete.
	- **Status-based**: you will have to define fixed %&nbsp;Complete values for each [work package status](../work-package-status), which will update automatically when team members update the status of their work packages.

5. **Default highlighting mode** (Enterprise add-on) defines which should be the default [attribute highlighting](../../../user-guide/work-packages/work-package-table-configuration/#attribute-highlighting-enterprise-add-on) mode, e.g. to highlight the following criteria in the work package table. This setting is only available for Enterprise on-premises and Enterprise cloud users.

   ![default highlighting mode](openproject_system_guide_default_highlighting_mode.png)

6. Customize the appearance of the work package tables to **define which work package attributes are displayed in the work package tables by default**.

Do not forget to save your changes with the blue **Save** button at the bottom.

![work-package-settings-administration](openproject_system_guide_work_package_settings.png)
