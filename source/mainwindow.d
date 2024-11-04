module mainwindow;

import std.stdio;
import std.conv;

import core.stdcpp.new_;
import qt.core.object;
import qt.core.string;
import qt.core.point;
import qt.core.variant;
import qt.helpers;

import qt.widgets.ui;
import qt.widgets.mainwindow;
import qt.widgets.dialog;
import qt.widgets.widget;
import qt.widgets.label;
import qt.widgets.pushbutton;
import qt.widgets.menu;
import qt.widgets.action;

import qt.gui.font;
import qt.gui.icon;

import qt.core.abstractitemmodel;

import d2sqlite3;

import taskmodel;
import worklogmodel;
import editworklogdialog;
import edittaskdialog;

class MainWindow : QMainWindow {

    mixin(Q_OBJECT_D);

    this(QWidget parent = null, Database db) {

        this.db = db;

        super(parent);

        setWindowIcon(QIcon.fromTheme(QString("evolution-tasks")));

        this.ui = cpp_new!(typeof(*ui));

        ui.setupUi(this);

        // setup the rest of the UI

        // TODO: consider changing to Actions Context menu from QT Designer

        // work log context menu
        workLogContextMenu = new QMenu(this);
        QAction editAction = new QAction(QString("Edit"), this);
        connect(editAction.signal!("triggered"), this.slot!("onEditWorkLogClicked"));
        workLogContextMenu.addAction(editAction);

        QAction deleteAction = new QAction(QString("Delete"), this);
        connect(deleteAction.signal!("triggered"), this.slot!("onDeleteWorkLogClicked"));
        workLogContextMenu.addAction(deleteAction);

        // task model context menu
        taskContextMenu = new QMenu(this);
        QAction addTaskAction = new QAction(QString("Add Task"), this);
        connect(addTaskAction.signal!("triggered"), this.slot!("onAddTaskClicked"));
        taskContextMenu.addAction(addTaskAction);

        // task model
        taskModel = new TaskModel(db);
        ui.taskTreeView.setModel(taskModel);
        ui.taskTreeView.setExpanded(taskModel.index(0, 0), true);
        ui.taskTreeView.setColumnWidth(0, 200);

        connect(ui.taskTreeView.signal!("customContextMenuRequested"),
            this.slot!("onTaskContextMenuRequested"));

        connect(ui.taskTreeView.selectionModel().signal!("currentChanged"),
            this.slot!("onCurrentTaskChanged"));

        // work log model
        workLogModel = new WorkLogModel(db);
        ui.workLogTableView.setModel(workLogModel);
        ui.workLogTableView.setColumnWidth(0, 200);

        connect(ui.workLogTableView.signal!("customContextMenuRequested"),
            this.slot!("onWorkLogContextMenuRequested"));

        connect(ui.btnAddWorkLog.signal!("clicked"),
            this.slot!("onAddWorkLogClicked"));

    }

    ~this() {
        cpp_delete(ui);
    }

    /////////
    // Task methods
    //////////
    @QSlot public void onCurrentTaskChanged(ref const(QModelIndex) current, ref const(QModelIndex) previous) {
        currentTask = cast(Task)current.internalPointer;
        writeln("Selected task: ", currentTask.id , ", ", currentTask.description);
        workLogModel.setTask(currentTask.id);
    }

    @QSlot public void onTaskContextMenuRequested(ref const QPoint pos) {
        writeln("Context menu tasks requested");
        QModelIndex index = ui.taskTreeView.indexAt(pos);
        if (index.isValid()) {
            // FIXME: dependency issue with accessing internalPointer
            currentTask = cast(Task)index.internalPointer;
            taskContextMenu.exec(ui.taskTreeView.mapToGlobal(pos));
        }
    }

    @QSlot public void onAddTaskClicked() {
        writeln("Add task");
        auto dialog = new EditTaskDialog(this);
        Task taskItem = new Task();
        dialog.setTaskItem(taskItem);
        dialog.exec();
        if (dialog.result() == QDialog.DialogCode.Accepted) {
            taskModel.addTask(currentTask, taskItem);
        }
    }

    ///////////////
    //// Work Log methods
    //////////////


    @QSlot public void onWorkLogContextMenuRequested(ref const QPoint pos) {
        writeln("Context menu worklog requested");
        // index = ui.workLogTableView.currentIndex; // alternative
        QModelIndex index = ui.workLogTableView.indexAt(pos);
        if (index.isValid()) {
            // FIXME: dependency issue with accessing internalPointer
            currentWorkLog = cast(WorkLog)index.internalPointer;
            workLogContextMenu.exec(ui.workLogTableView.mapToGlobal(pos));
        }
    }

    @QSlot public void onEditWorkLogClicked() {
        writeln("Edit");
        auto dialog = new EditWorkLogDialog(this);
        dialog.setWorkLogItem(currentWorkLog);
        dialog.exec();
        if (dialog.result() == QDialog.DialogCode.Accepted) {
            workLogModel.updateWorkLog(currentWorkLog);
        }
    }

    @QSlot public void onAddWorkLogClicked() {
        auto dialog = new EditWorkLogDialog(this);
        WorkLog workLog = new WorkLog();
        dialog.setWorkLogItem(workLog);
        dialog.exec();
        if (dialog.result() == QDialog.DialogCode.Accepted) {
            workLogModel.addWorkLog(workLog, currentTask.id);
        }
    }

    @QSlot public void onDeleteWorkLogClicked() {
        writeln("Delete");
        workLogModel.deleteWorkLog(currentWorkLog);
        currentWorkLog = null;
    }

private:
    UIStruct!"mainwindow.ui"* ui;

    TaskModel taskModel;
    WorkLogModel workLogModel;

    QMenu workLogContextMenu;
    QMenu taskContextMenu;

    uint taskId;

    Database db;

    Task currentTask;
    WorkLog currentWorkLog;

}
