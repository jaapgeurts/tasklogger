module editworklogdialog;

import std.stdio;
import std.conv;

import core.stdcpp.new_;
import qt.core.object;
import qt.core.string;
import qt.core.variant;
import qt.core.datetime;
import qt.helpers;

import qt.widgets.ui;
import qt.widgets.dialog;
import qt.widgets.widget;
import qt.widgets.label;

import qt.widgets.pushbutton;

import worklogmodel;


class EditWorkLogDialog : QDialog {

    mixin(Q_OBJECT_D);

    this(QWidget parent = null) {

        super(parent);

        this.ui = cpp_new!(typeof(*ui));

        ui.setupUi(this);

        ui.dteStartDate.setDateTime(QDateTime.currentDateTime);

        connect(this.signal!("accepted"), this.slot!("onAccepted"));

    }

    ~this() {
        cpp_delete(ui);
    }

    void setWorkLogItem(WorkLog item) {
        workLogItem = item;
        ui.leTitle.setText(QString(item.title));
        ui.spMinutes.setValue(item.minutes);
        ui.dteStartDate.setDateTime(QDateTime.fromString(QString(item.date), QString("yyyy-MM-dd hh:mm:ss.zzz")));
    }

    @QSlot void onAccepted() {
        workLogItem.title = ui.leTitle.text.toUtf8().data.to!string;
        workLogItem.minutes = ui.spMinutes.value;
        workLogItem.date = ui.dteStartDate.dateTime.toString(QString("yyyy-MM-dd hh:mm:ss.zzz")).toUtf8().data.to!string;
        writeln("Accepted: ", workLogItem.title);
    }

private:
    UIStruct!"editworklogdialog.ui"* ui;

    WorkLog workLogItem;

}
