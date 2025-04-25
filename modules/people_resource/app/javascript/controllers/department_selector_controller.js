import { Controller } from "@hotwired/stimulus"

// 部门选择器控制器
export default class extends Controller {
  static targets = [
    "dropdown", 
    "selectedContainer", 
    "selectButton", 
    "checkbox",
    "tag"
  ]

  connect() {
    console.log("Department selector controller connected")
    // 初始化时为所有复选框添加事件监听器
    this.checkboxTargets.forEach(checkbox => {
      checkbox.addEventListener('change', this.handleCheckboxChange.bind(this))
    })
  }

  // 打开部门选择面板
  open(event) {
    event.preventDefault()
    this.dropdownTarget.style.display = 'block'
  }

  // 关闭部门选择面板
  close() {
    this.dropdownTarget.style.display = 'none'
  }

  // 确认选择
  confirm() {
    // 清除现有的隐藏字段
    const hiddenFields = this.selectedContainerTarget.querySelectorAll('input[type="hidden"]')
    hiddenFields.forEach(el => el.remove())
    
    // 获取所有选中的部门
    const selectedCheckboxes = this.checkboxTargets.filter(cb => cb.checked)
    const selectedDepts = []
    
    // 筛选出叶子节点部门（没有被选中的子部门的部门）
    selectedCheckboxes.forEach(checkbox => {
      const id = checkbox.value
      let isLeafNode = true
      
      // 检查是否有子部门也被选中
      const childItems = document.querySelectorAll(`.department-item[data-parent="${id}"]`)
      childItems.forEach(item => {
        const childCheckbox = item.querySelector('input[type="checkbox"]')
        if (childCheckbox && childCheckbox.checked) {
          isLeafNode = false
        }
      })
      
      // 如果是叶子节点或没有子部门，则添加到选中列表
      if (isLeafNode) {
        const name = document.querySelector(`label[for="department_select_${id}"]`).textContent
        selectedDepts.push({id, name})
      }
    })
    
    // 清除现有标签
    this.element.querySelectorAll('.department-tag').forEach(el => el.remove())
    
    // 添加新标签和隐藏字段
    selectedDepts.forEach(dept => {
      const tag = document.createElement('span')
      tag.className = 'department-tag'
      tag.innerHTML = dept.name + `<a href="#" class="remove-tag" data-id="${dept.id}" data-action="click->department-selector#removeTag">×</a>`
      
      const hiddenField = document.createElement('input')
      hiddenField.type = 'hidden'
      hiddenField.name = 'department_ids[]'
      hiddenField.value = dept.id
      
      this.selectedContainerTarget.insertBefore(tag, this.selectButtonTarget)
      this.selectedContainerTarget.appendChild(hiddenField)
    })
    
    // 隐藏下拉面板
    this.close()
  }

  // 删除标签
  removeTag(event) {
    event.preventDefault()
    const id = event.currentTarget.getAttribute('data-id')
    event.currentTarget.parentNode.remove()
    
    // 移除隐藏字段
    const hiddenField = this.selectedContainerTarget.querySelector(`input[value="${id}"]`)
    if (hiddenField) hiddenField.remove()
    
    // 取消选中对应的复选框
    const checkbox = document.getElementById(`department_select_${id}`)
    if (checkbox) checkbox.checked = false
  }

  // 处理复选框状态变化
  handleCheckboxChange(event) {
    const checkbox = event.target
    const isChecked = checkbox.checked
    const deptId = checkbox.value
    
    // 如果选中，则选中所有子部门
    if (isChecked) {
      this.selectAllChildren(deptId)
    } 
    // 如果取消选中，则取消所有子部门
    else {
      this.unselectAllChildren(deptId)
    }
    
    // 检查父部门状态
    this.updateParentCheckboxes()
  }

  // 选中所有子部门
  selectAllChildren(parentId) {
    // 找到所有子部门的复选框
    const childrenItems = document.querySelectorAll(`.department-item[data-parent="${parentId}"]`)
    childrenItems.forEach(item => {
      const checkbox = item.querySelector('input[type="checkbox"]')
      if (checkbox) {
        checkbox.checked = true
        // 递归选中子部门的子部门
        this.selectAllChildren(checkbox.value)
      }
    })
  }

  // 取消选中所有子部门
  unselectAllChildren(parentId) {
    // 找到所有子部门的复选框
    const childrenItems = document.querySelectorAll(`.department-item[data-parent="${parentId}"]`)
    childrenItems.forEach(item => {
      const checkbox = item.querySelector('input[type="checkbox"]')
      if (checkbox) {
        checkbox.checked = false
        // 递归取消选中子部门的子部门
        this.unselectAllChildren(checkbox.value)
      }
    })
  }

  // 更新父部门复选框状态
  updateParentCheckboxes() {
    // 从底层开始向上更新
    const allItems = document.querySelectorAll('.department-item[data-parent]')
    const itemsByParent = {}
    
    // 按父ID分组
    allItems.forEach(item => {
      const parentId = item.getAttribute('data-parent')
      if (!itemsByParent[parentId]) {
        itemsByParent[parentId] = []
      }
      itemsByParent[parentId].push(item)
    })
    
    // 处理每个父部门
    Object.keys(itemsByParent).forEach(parentId => {
      const parentCheckbox = document.getElementById(`department_select_${parentId}`)
      if (!parentCheckbox) return
      
      const children = itemsByParent[parentId]
      const childCheckboxes = children.map(item => item.querySelector('input[type="checkbox"]'))
      
      // 如果所有子部门都被选中，则选中父部门
      const allChecked = childCheckboxes.every(cb => cb && cb.checked)
      if (allChecked) {
        parentCheckbox.checked = true
      }
      
      // 如果没有子部门被选中，则取消选中父部门
      const noneChecked = childCheckboxes.every(cb => cb && !cb.checked)
      if (noneChecked) {
        parentCheckbox.checked = false
      }
    })
  }
} 