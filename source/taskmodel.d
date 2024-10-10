module taskmodel;

import std.stdio;
import std.typecons;
import std.algorithm.searching;
import std.algorithm.iteration;
import std.conv;

import qt.helpers;
import qt.core.namespace;
import qt.core.abstractitemmodel;
import qt.core.string;
import qt.core.variant;

import d2sqlite3;

class Task {

    this() {
        this.id = -1;
    } // required for registertype

    this(uint parentId) {
        this.id = -1;
        this.parentId = parentId;
    }

    this(string description) {
        this(-1, description, Nullable!uint.init);
    }

    this(uint id, string description, Nullable!uint parentId) {
        this.id = id;
        this.description = description;
        this.parentId = parentId;
    }

    uint id;
    Nullable!uint parentId;

    string description;

}

class TaskModel : QAbstractItemModel {

public:

    this(Database db) {
        this.db = db;

        fetchData();

    }

    ~this() {
    }

    public void addTask(Task task, uint parentId = 0) {
        beginResetModel();
        // add the task to the database
        db.execute("INSERT INTO Task (Description, ParentId) VALUES (:description, :parentid);", task.description, parentId);

        task.parentId = parentId;
        // update the model
        content ~= task;

        endResetModel();
    }

    private void fetchData() {

        auto count = db.execute("SELECT count(*) FROM Task;").oneValue!uint;
        content = new Task[count];

        auto results = db.execute("SELECT Id, Description, ParentId FROM Task;");

        int i = 0;
        foreach (Row row; results) {
            writeln("Adding task");

            content[i] = new Task(row["Id"].as!uint, row["Description"].as!string, row["ParentId"].as!(
                    Nullable!uint));
            i++;
        }
    }

    Task at(ulong index) {
        return content[index];
    }

    extern (C++) override int columnCount(ref const(QModelIndex) parent = globalInitVar!QModelIndex) const {
        return 1;
    }

    // return the number of rows for the parent
    extern (C++) override int rowCount(ref const(QModelIndex) parent = globalInitVar!QModelIndex) const {

        if (!parent.isValid())
            return content.count!(e => e.parentId.isNull)
                .to!int;

        const(Task) parentItem = content.find!(e => e.id == parent.internalId)[0];

        int rc = content.count!(e => e.parentId == parentItem.id)
            .to!int;
        // writeln("Getting row count for parent: ", parent.row(), ": ", rc);
        return rc;
    }

    extern (C++) override QVariant data(ref const(QModelIndex) index, int role = qt
            .core.namespace.ItemDataRole.DisplayRole) const {
        if (!index.isValid())
            return QVariant();

        if (role != qt.core.namespace.ItemDataRole.DisplayRole)
            return QVariant();

        return QVariant(QString(content.find!(e => e.id == index.internalId)[0].description));
    }

    extern (C++) override qt.core.namespace.ItemFlags flags(ref const(QModelIndex) index) const {
        if (!index.isValid())
            return qt.core.namespace.ItemFlags.NoItemFlags;

        return QAbstractItemModel.flags(index) | qt.core.namespace.ItemFlag.ItemIsEditable;
    }

    extern (C++) override bool setData(ref const(QModelIndex) index, ref const(QVariant) value, int role) {
        // if (role != qt.core.namespace.ItemDataRole.EditRole)
        //     return false;

        // int[2] key = [index.column(), index.row()];
        // content[key] = value.toString();
        // QVector!(int) roles = QVector!(int).create();
        // roles.append(qt.core.namespace.ItemDataRole.DisplayRole);
        // roles.append(qt.core.namespace.ItemDataRole.EditRole);
        // /+ emit +/ dataChanged(index, index, roles);

        return false;
    }

    extern (C++) override QModelIndex index(int row, int column, ref const(QModelIndex) parent = globalInitVar!QModelIndex) const {

        if (!hasIndex(row, column, parent))
            return QModelIndex();

        // writeln("Creating index for row: ", row);

        import std.range;

        if (parent.isValid()) {
            // first get the parent item
            const(Task) parentItem = content.find!(e => e.id == parent.internalId)[0];
            // get the child items
            // does this the parent have a child at this row?
            auto childItems = content.filter!(e => e.parentId == parentItem.id);
            if (row < childItems.count) {
                return createIndex(row, column, childItems.drop(row).front().id);
            }
        }
        else {
            return createIndex(row, column, content.filter!(e => e.parentId.isNull)
                    .drop(row).front().id);
        }

        return QModelIndex();
    }

    extern (C++) override QModelIndex parent(ref const(QModelIndex) index) const {

        if (!index.isValid())
            return QModelIndex();

        // writeln("Finding parent for id: ", index.internalId);

        // find the child item
        const(Task) childItem = content.find!(e => e.id == index.internalId)[0];

        // The child is a top level item
        if (childItem.parentId.isNull)
            return QModelIndex();

        // Get the parent item for this child
        const(Task) parentItem = content.find!(e => e.id == childItem.parentId)[0];

        // get the row number of the parent in its parent
        if (parentItem.parentId.isNull) {
            auto items = content.filter!(e => e.parentId.isNull);
            return createIndex(items.countUntil!(e => e.id == parentItem.id)
                    .to!int, 0, parentItem.id);
        }
        else {
            int itemNo = content.filter!(e => e.id == childItem.parentId)
                .countUntil!(e => e.id == parentItem.id)
                .to!int;
            return createIndex(itemNo, 0, parentItem.id);
        }

    }

    extern (C++) override QVariant headerData(int section, qt.core.namespace.Orientation orientation, int role) const {
        if (orientation == qt.core.namespace.Orientation.Horizontal && role == qt
            .core.namespace.ItemDataRole.DisplayRole) {
            if (section == 0)
                return QVariant(QString("Name"));
        }

        // if (orientation == qt.core.namespace.Orientation.Vertical && role == qt.core.namespace.ItemDataRole.DisplayRole)
        // {
        //     return QVariant(QString.number(section + 1));
        // }

        return QVariant();
    }

private:
    Task[] content;
    Database db;
}
