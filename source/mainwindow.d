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

class MainWindow : QMainWindow {

    mixin(Q_OBJECT_D);

    this(QWidget parent = null, Database db) {

        this.db = db;

        super(parent);

        this.ui = cpp_new!(typeof(*ui));

        ui.setupUi(this);

        // setup the rest of the UI

        workLogContextMenu = new QMenu(this);
        QAction editAction = new QAction(QString("Edit"), this);
        connect(editAction.signal!("triggered"),this.slot!("onEditWorkLogClicked"));
        workLogContextMenu.addAction(editAction);

        taskModel = new TaskModel(db);
        ui.taskTreeView.setModel(taskModel);

        connect(ui.taskTreeView.selectionModel().signal!("currentChanged"), 
            this.slot!("onCurrentTaskChanged"));

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

    @QSlot public void onCurrentTaskChanged(ref const(QModelIndex) current,ref const(QModelIndex) previous) {
        taskId = current.internalId.to!uint;
        workLogModel.setTask(taskId);
    }

    @QSlot public void onAddWorkLogClicked() {
        auto dialog = new EditWorkLogDialog(this); 
        WorkLog workLog = new WorkLog(taskId);
        dialog.setWorkLogItem(workLog);
        dialog.exec();
        if (dialog.result() == QDialog.DialogCode.Accepted) {
            workLogModel.addWorkLog(workLog);
        }
    }

    // TODO: change to local variable
    QModelIndex index;

    @QSlot public void onWorkLogContextMenuRequested(ref const QPoint pos) {
        writeln("Context menu requested");
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

private:
    UIStruct!"mainwindow.ui"* ui;

    TaskModel taskModel;
    WorkLogModel workLogModel;

    QMenu workLogContextMenu;

    uint taskId;

    Database db;

}
