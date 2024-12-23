//
//  ContentView.swift
//  To Do List
//
//  Created by 李熙欣 on 2024/12/7.
//

import SwiftUI

struct Task: Identifiable {
    let id = UUID()
    var name: String
    var dueDate: Date
    var category: String
    var isCompleted: Bool = false
    var details: String? = nil
}

struct Category: Identifiable {
    let id = UUID()
    var name: String
}


class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var categories: [Category] = [Category(name: "Work"), Category(name: "Personal")]
    @Published var selectedFilter: String = "All" // "All", "Pending", "Completed"
    @Published var selectedCategory: String? = nil
    
    var filteredTasks: [Task] {
        tasks.filter { task in
            switch selectedFilter {
            case "Pending":
                return !task.isCompleted
            case "Completed":
                return task.isCompleted
            default:
                return true
            }
        }
        .filter { task in
            if let category = selectedCategory {
                return task.category == category
            }
            return true
        }
    }
    
    func addTask(name: String, dueDate: Date, category: String, details: String?) {
        tasks.append(Task(name: name, dueDate: dueDate, category: category, details: details))
    }
    
    func addCategory(name: String) {
        categories.append(Category(name: name))
    }
    
    func pendingTasks(for date: Date) -> [Task] {
            return tasks.filter { task in
                !task.isCompleted && Calendar.current.isDate(task.dueDate, inSameDayAs: date)
            }
        }
}

struct ToDoListView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var isAddingTask = false
    @State private var isAddingCategory = false
    @State private var showAddOptions = false
    @State private var isSelectingCategory = false
    @State private var isFilterSheetPresented = false

    var body: some View {
        NavigationStack {
            VStack {
                CalendarView(viewModel: viewModel)
                    .padding(.top, -60)
                Button(action: {
                    withAnimation {
                        isFilterSheetPresented = true
                    }
                }) {
                    HStack {
                        Text("Filter: \(viewModel.selectedFilter)")
                            .font(Font.custom("ArialRoundedMTBold", size: 20))
                        
                        Spacer()
                        Image(systemName: "chevron.up")
                    }
                    .font(Font.custom("ArialRoundedMTBold", size: 20)) // Apply custom font to this button
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Task List
                List {
                    ForEach(viewModel.filteredTasks) { task in
                        TaskRow(viewModel: viewModel, task: task)
                    }
                    .onDelete(perform: deleteTask)
                }

                Button(action: {
                    withAnimation {
                        showAddOptions.toggle()
                    }
                }) {
                    Image(systemName: "plus")
                        .bold()
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(50)
                        .shadow(radius: 10)
                }
                .actionSheet(isPresented: $showAddOptions) {
                    ActionSheet(
                        title: Text("Add"),
                        message: Text("What would you like to add?"),
                        buttons: [
                            .default(Text("Add Task")) {
                                isAddingTask = true
                            },
                            .default(Text("Add Category")) {
                                isAddingCategory = true
                            },
                            .cancel()
                        ]
                    )
                }
            }
            
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(viewModel: viewModel)
            }
            .sheet(isPresented: $isAddingCategory) {
                AddCategoryView(viewModel: viewModel)
            }
            .sheet(isPresented: $isSelectingCategory) {
                CategorySelectionView(viewModel: viewModel, isSelectingCategory: $isSelectingCategory)
            }
            .toolbar {
                
                ToolbarItem(placement: .principal) {
                    Text(viewModel.selectedCategory ?? "All Categories")
                        .font(Font.custom("ArialRoundedMTBold", size: 30))
                        .foregroundColor(.white)
                        .padding()
                }
                
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Change") {
                        isSelectingCategory = true
                    }
                }
            }
            .bottomSheet(isPresented: $isFilterSheetPresented) {
                FilterSheet(viewModel: viewModel, isPresented: $isFilterSheetPresented)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteTask(at offsets: IndexSet) {
        viewModel.tasks.remove(atOffsets: offsets)
    }
}



struct FilterSheet: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Filter Tasks")
               // .font(.headline)
                .font(Font.custom("ArialRoundedMTBold", size: 20))
                .padding()

            Button(action: {
                viewModel.selectedFilter = "All"
                isPresented = false
            }) {
                Text("All")
                    .font(Font.custom("ArialRoundedMTBold", size: 20))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.selectedFilter == "All" ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(viewModel.selectedFilter == "All" ? .white : .primary)
                    .cornerRadius(8)
            }

            Button(action: {
                viewModel.selectedFilter = "Pending"
                isPresented = false
            }) {
                Text("Pending")
                    .font(Font.custom("ArialRoundedMTBold", size: 20))
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.selectedFilter == "Pending" ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(viewModel.selectedFilter == "Pending" ? .white : .primary)
                    .cornerRadius(8)
            }

            Button(action: {
                viewModel.selectedFilter = "Completed"
                isPresented = false
            }) {
                Text("Completed")
                    .font(Font.custom("ArialRoundedMTBold", size: 20))
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(viewModel.selectedFilter == "Completed" ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(viewModel.selectedFilter == "Completed" ? .white : .primary)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .background(Color.black)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

extension View {
    /// A custom bottom sheet modifier
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented.wrappedValue = false
                    }

                VStack {
                    Spacer()

                    content()
                        .frame(maxWidth: .infinity, maxHeight: 350)
                        .background(Color.black)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: isPresented.wrappedValue)
                .background(Color.clear)
            }
        }
    }
}


struct FilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .padding()
                .background(isSelected ? Color.blue : Color.gray.opacity(0.6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct TaskRow: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var showDetails = false
    var task: Task

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.name)
                    .strikethrough(task.isCompleted, color: .gray) // Crosscut if completed
                    .foregroundColor(task.isCompleted ? .gray : .primary)

                
                Text(task.dueDate, style: .date) // Display formatted date
                        .font(.subheadline)
                        .foregroundColor(.gray)
            

                if let taskDetails = task.details {
                    Text(taskDetails)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1) // Keep the details short in the row
                }
            }
            Spacer()
            if task.isCompleted {
                Image(systemName: "checkmark.circle")
            }
            else {
                Image(systemName: "clock")
            }
        }
        .padding()
        .contentShape(Rectangle()) // Make the entire row tappable
        .onTapGesture {
            // Toggle completion status
            if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                viewModel.tasks[index].isCompleted.toggle()
            }
        }
        .contextMenu {
            // Modify Task button
            Button(action: {
                showDetails = true
            }) {
                Text("Modify Task")
                Image(systemName: "pencil.circle")
            }
        }
        .sheet(isPresented: $showDetails) {
            TaskDetailsView(task: task, viewModel: viewModel)
        }
    }
}


struct TaskDetailsView: View {
    @Environment(\.dismiss) var dismiss // To dismiss the view
    @ObservedObject var viewModel: TaskViewModel
    @State private var taskName: String
    @State private var taskDetails: String
    @State private var taskDueDate: Date

    var task: Task

    init(task: Task, viewModel: TaskViewModel) {
        self.task = task
        self.viewModel = viewModel
        _taskName = State(initialValue: task.name)
        _taskDetails = State(initialValue: task.details ?? "")
        _taskDueDate = State(initialValue: task.dueDate)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Task Name (Editable)
                TextField("Task Name", text: $taskName)
                    //.font(.title)
                    .font(Font.custom("ArialRoundedMTBold", size: 18))
                    .bold()
                    .padding(.top)

                // Due Date (Editable)
                DatePicker("Due Date", selection: $taskDueDate, displayedComponents: .date)
                    .font(Font.custom("ArialRoundedMTBold", size: 18))
                    .padding(.top)

                Divider()

                // Task Details (Editable)
                Text("Notes:")
                    .font(Font.custom("ArialRoundedMTBold", size: 18))
                    .padding(.top)
                TextEditor(text: $taskDetails)
                    //.font(.body)
                    .font(Font.custom("ArialRoundedMTBold", size: 15))
                    .padding(.top)

                //Spacer()
            }
            .offset(y: -50)
            .padding()
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Tasks Details")
                        .font(Font.custom("ArialRoundedMTBold", size: 30))
                        .foregroundColor(.white) // Optional color change
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    // Update the task in the viewModel
                    if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                        viewModel.tasks[index].name = taskName
                        viewModel.tasks[index].details = taskDetails
                        viewModel.tasks[index].dueDate = taskDueDate
                    }
                    dismiss() // Close the view after saving
                }
            )
        }
    }
}

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var name = ""
    @State private var dueDate = Date()
    @State private var selectedCategory: String?
    @State private var details: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")
                    .font(.custom("ArialRoundedMTBold", size: 18))) {
                    TextField("Task Name", text: $name)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }

                Section(header: Text("Category")
                    .font(.custom("ArialRoundedMTBold", size: 18))) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(viewModel.categories) { category in
                            Text(category.name).tag(category.name as String?)
                        }
                    }
                }
                
                Section(header: Text("Notes")
                    .font(.custom("ArialRoundedMTBold", size: 18))) {
                    TextField("Details", text: $details)
                }
            }
            .navigationBarTitle("Add Task", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }, trailing: Button("Save") {
                if let category = selectedCategory {
                    viewModel.addTask(name: name, dueDate: dueDate, category: category, details: details)
                }
                dismiss()
            })
        }
    }
}
struct CalendarView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State public var color: Color = .blue
    @State private var date = Date.now
    let daysOfWeek = Date.capitalizedFirstLettersOfWeekdays
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var days: [Date] = []
    
    @State private var tasksForSelectedDate: [Task] = []
    @State private var showTasksSheet = false

    var body: some View {
        VStack {
            // Date Picker to change the calendar month/year
            DatePicker("Select Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .frame(width: .infinity,height: .infinity)
                .padding()
                .font(Font.custom("ArialRoundedMTBold", size: 18))

            HStack {
                ForEach(daysOfWeek.indices, id: \.self) { index in
                    Text(daysOfWeek[index])
                        .fontWeight(.black)
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns) {
                ForEach(days, id: \.self) { day in
                    if day.monthInt != date.monthInt {
                        Text("")
                            .offset(y: -15)
                            .padding()
                    } else {
                        ZStack {
                            Text(day.formatted(.dateTime.day()))
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(
                                    Circle()
                                        .foregroundStyle(
                                            Date.now.startOfDay == day.startOfDay
                                            ? .red.opacity(0.3)
                                            : color.opacity(0.3)
                                        )
                                )

                            // Show a dot if there are pending tasks on this date
                            if !viewModel.pendingTasks(for: day).isEmpty {
                                Circle()
                                    .offset(y: 18)
                                    .fill(Color.red) // Dot color
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 4)
                                    .onTapGesture {
                                        showTasksForDay(day)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            days = date.calendarDisplayDays
        }
        .onChange(of: date) {
            days = date.calendarDisplayDays
        }
        .sheet(isPresented: $showTasksSheet) {
            TasksForDayView(tasks: tasksForSelectedDate)
        }
    }

    func showTasksForDay(_ day: Date) {
        tasksForSelectedDate = viewModel.pendingTasks(for: day)
        showTasksSheet = true
    }
}

struct TasksForDayView: View {
    var tasks: [Task]

    var body: some View {
        NavigationView {
            List(tasks) { task in
                VStack(alignment: .leading) {
                    Text(task.name)
                        .font(.headline)
                    Text(task.dueDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Tasks for the Day")
                            .font(Font.custom("ArialRoundedMTBold", size: 30))
                            .foregroundColor(.white)
                            .padding()
                            .offset(y: 30)
                    }
                }
        }
    }
}



struct AddCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var name = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $name)
            }
            .navigationBarTitle("Add Category", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }, trailing: Button("Save") {
                viewModel.addCategory(name: name)
                dismiss()
            })
        }
    }
}

struct CategorySelectionView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var isSelectingCategory: Bool

    var body: some View {
        NavigationView {
            List {
                Button("All Categories") {
                    viewModel.selectedCategory = nil
                    isSelectingCategory = false
                }
                .font(Font.custom("ArialRoundedMTBold", size: 20))
                .bold()
                .foregroundColor(viewModel.selectedCategory == nil ? .blue : .primary)

                ForEach(viewModel.categories) { category in
                    Button(category.name) {
                        viewModel.selectedCategory = category.name
                        isSelectingCategory = false
                    }
                    .bold()
                    .foregroundColor(viewModel.selectedCategory == category.name ? .blue : .primary)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select Category")
                        .font(Font.custom("ArialRoundedMTBold", size: 30))
                        .foregroundColor(.white) // Optional color change
                }
            }
            .navigationBarItems(leading: Button("Cancel") {
                isSelectingCategory = false
            })
        }
    }
}

/*
 .navigationTitle("")  // Clear the default title
 .toolbar {
     ToolbarItem(placement: .principal) {
         Text("Tasks for the Day")
             .font(Font.custom("ArialRoundedMTBold", size: 30))
             .foregroundColor(.white) // Optional color change
     }
 }
 
 */


#Preview(){
    ToDoListView()
}

