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

        this.ui = cpp_new!(typeof(*ui));

        ui.setupUi(this);

        // setup the rest of the UI

        // TODO: consider changing to Actions Context menu from QT Designer

        // work log context menu
        workLogContextMenu = new QMenu(this);
        QAction editAction = new QAction(QString("Edit"), this);
        connect(editAction.signal!("triggered"), this.slot!("onEditWorkLogClicked"));
        workLogContextMenu.addAction(editAction);

        // task model context menu
        taskContextMenu = new QMenu(this);
        QAction addTaskAction = new QAction(QString("Add Task"), this);
        connect(addTaskAction.signal!("triggered"), this.slot!("onAddTaskClicked"));
        taskContextMenu.addAction(addTaskAction);

        // task model
        taskModel = new TaskModel(db);
        ui.taskTreeView.setModel(taskModel);
        connect(ui.taskTreeView.signal!("customContextMenuRequested"),
            this.slot!("onTaskContextMenuRequested"));

        connect(ui.taskTreeView.selectionModel().signal!("currentChanged"),
            this.slot!("onCurrentTaskChanged"));

        // work log model
        workLogModel = new WorkLogModel(db);
        ui.workLogTableView.setModel(workLogModel);
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
        taskId = current.internalId.to!uint;
        workLogModel.setTask(taskId);
    }

    @QSlot public void onTaskContextMenuRequested(ref const QPoint pos) {
        writeln("Context menu tasks requested");
        index = ui.taskTreeView.indexAt(pos);
        if (index.isValid()) {
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
            taskModel.addTask(taskItem, taskId);
        }
    }

    ///////////////
    //// Work Log methods
    //////////////

    // TODO: change to local variable
    QModelIndex index;

    @QSlot public void onWorkLogContextMenuRequested(ref const QPoint pos) {
        writeln("Context menu worklog requested");
        // index = ui.workLogTableView.currentIndex; // alternative
        index = ui.workLogTableView.indexAt(pos);
        if (index.isValid()) {
            workLogContextMenu.exec(ui.workLogTableView.mapToGlobal(pos));
        }
    }

    @QSlot public void onEditWorkLogClicked() {
        writeln("Edit");
        WorkLog workLog = workLogModel.at(index.row);
        auto dialog = new EditWorkLogDialog(this);
        dialog.setWorkLogItem(workLog);
        dialog.exec();
        if (dialog.result() == QDialog.DialogCode.Accepted) {
            workLogModel.updateWorkLog(workLog);
        }
    }

    @QSlot public void onAddWorkLogClicked() {
        auto dialog = new EditWorkLogDialog(this);
        WorkLog workLog = new WorkLog();
        dialog.setWorkLogItem(workLog);
        dialog.exec();
        if (dialog.result() == QDialog.DialogCode.Accepted) {
            workLogModel.addWorkLog(workLog, taskId);
        }
    }

private:
    UIStruct!"mainwindow.ui"* ui;

    TaskModel taskModel;
    WorkLogModel workLogModel;

    QMenu workLogContextMenu;
    QMenu taskContextMenu;

    uint taskId;

    Database db;

}
