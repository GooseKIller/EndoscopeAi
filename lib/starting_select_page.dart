import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'records.dart';
import 'apps_routes.dart';

void _openVideoPlayer(BuildContext context, RecordData record) {
  Navigator.pushNamed(context, AppsRoutes.fileVideoPlayer, arguments: record);
}

// A page with page selecting
class StartingSelecetPage extends StatefulWidget {
  const StartingSelecetPage({super.key});

  @override
  State<StartingSelecetPage> createState() => _StartingSelecetPageState();
}

enum _projectActionState { NONE, DELETE }

class _StartingSelecetPageState extends State<StartingSelecetPage> {
  // A list of loaded records
  late List<RecordData> _records;
  // A state, that represent buttots' actions in the right of the item list
  _projectActionState _actionState = _projectActionState.NONE;

  /// Utillity
  // Load saved records
  void _loadRecords() {
    setState(() {
      _records = loadRecords();
    });
  }

  // Toggle
  void _toggleState(_projectActionState value) {
    setState(() {
      if (_actionState == value) {
        // reset to folder view
        _actionState = _projectActionState.NONE;
      } else {
        // set new
        _actionState = value;
      }
    });
  }

  // Get color with opacity in respect of state
  Color _actionButtonGetOpacity(_projectActionState state) {
    Color color = Colors.grey;

    if (_actionState != _projectActionState.NONE) {
      if (_actionState != state) {
        color = color.withOpacity(0.5);
      } else {
        color = Colors.red.shade600;
      }
    }

    return color;
  }

  /// actions
  void _newProject() {
    print("Creating new project");
    createRecordBase(PatientInfo(Uuid().v1().substring(0, 5)));
    _loadRecords();
  }

  void _createFromRecording() {
    print("Creating form existing");
  }

  void _openProject(BuildContext context, RecordData record) {
    print("Opening project #$record");
    _openVideoPlayer(context, record);
  }

  void _deleteProject(RecordData record) {
    print("Deleting project #$record");
    deleteRecord(record);
    _loadRecords();
  }

  void _locateProject(RecordData record) {
    print("Locating project #$record");
    locateRecord(record);
  }

  /// Widget creation
  Widget _getTailing(RecordData data) {
    switch (_actionState) {
      case _projectActionState.NONE:
        return IconButton(
          icon: Icon(Icons.folder),
          onPressed: () => _locateProject(data),
        );

      case _projectActionState.DELETE:
        return IconButton(
          icon: Icon(Icons.close),
          onPressed: () => _deleteProject(data),
          color: Colors.red.shade600,
        );
    }
  }

  // Creates item in list that creates new project
  Widget _buildNew(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.add_outlined),
      title: Text("New recodfing"),
      onTap: _newProject,
    );
  }

  // Create item in list that represents saved record
  Widget _buildItem(BuildContext context, int index) {
    final record = _records[index];
    final videoPath = record.videoPath;

    return ListTile(
      title: Text(record.patient.id), // Project name
      subtitle: Container(
        // project metadata
        child: Row(
          children: <Widget>[
            Text("Time: ${record.time}"),
            VerticalDivider(),
            Text("Path: $videoPath"),
          ],
        ),
      ),
      onTap: () => _openProject(context, _records[index]), // open project
      trailing: SizedBox(
        // action
        width: 32,
        height: 32,
        child: _getTailing(_records[index]),
      ),
    );
  }

  /// Overrides
  @override
  void initState() {
    super.initState();

    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // action bar
        backgroundColor: Colors.blueGrey,
        title: Container(
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.file_copy_rounded),
                onPressed: _newProject,
                tooltip: 'New record',
              ),
              IconButton(
                icon: Icon(Icons.open_in_new_rounded),
                onPressed: _createFromRecording,
                tooltip: 'Load recording from video',
              ),
              IconButton(
                icon: Icon(Icons.replay_outlined),
                onPressed: _loadRecords,
                tooltip: 'Reload',
              ),
              VerticalDivider(),

              // Action choose
              IconButton(
                onPressed: () => _toggleState(_projectActionState.DELETE),
                icon: Icon(Icons.delete),
                color: _actionButtonGetOpacity(_projectActionState.DELETE),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ListView.separated(
          separatorBuilder: (context, index) => Divider(),
          itemCount: _records.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildNew(context);
            } else {
              return _buildItem(context, index - 1);
            }
          },
        ),
      ),
    );
  }
}
