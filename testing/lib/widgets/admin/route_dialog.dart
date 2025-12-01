import 'package:flutter/material.dart';
import '../../controllers/stop_controller.dart';

class RouteDialog extends StatefulWidget {
  final String? routeCode;
  final List<Map<String, dynamic>>? existingStops;
  final Function(String code, List<Map<String, dynamic>> stops) onSave;

  const RouteDialog({
    Key? key,
    this.routeCode,
    this.existingStops,
    required this.onSave,
  }) : super(key: key);

  @override
  State<RouteDialog> createState() => _RouteDialogState();
}

class _RouteDialogState extends State<RouteDialog> {
  late TextEditingController _routeCodeController;
  late List<StopController> _stops;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _routeCodeController = TextEditingController(text: widget.routeCode ?? '');

    if (widget.existingStops != null && widget.existingStops!.isNotEmpty) {
      _stops = widget.existingStops!.map((stop) {
        return StopController(
          name: stop['name']?.toString() ?? '',
          lat: stop['lat']?.toString() ?? '',
          lng: stop['lng']?.toString() ?? '',
        );
      }).toList();
    } else {
      _stops = [StopController()];
    }
  }

  @override
  void dispose() {
    _routeCodeController.dispose();
    for (var stop in _stops) {
      stop.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() {
      _stops.add(StopController());
    });
  }

  void _removeStop(int index) {
    if (_stops.length > 1) {
      setState(() {
        _stops[index].dispose();
        _stops.removeAt(index);
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final stops = _stops.map((stop) {
        return {
          'name': stop.nameController.text.trim(),
          'lat': double.parse(stop.latController.text.trim()),
          'lng': double.parse(stop.lngController.text.trim()),
        };
      }).toList();

      widget.onSave(_routeCodeController.text.trim().toUpperCase(), stops);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.routeCode == null ? 'Add New Route' : 'Edit Route', style: TextStyle(fontWeight: FontWeight.w500),),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _routeCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Route Code',
                    hintText: 'e.g., 01B',
                    border: OutlineInputBorder(),
                  ),
                  enabled: widget.routeCode == null,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Route code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stops',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._stops.asMap().entries.map((entry) {
                  int index = entry.key;
                  StopController stop = entry.value;
                  return _buildStopField(index, stop);
                }).toList(),
                Center(
                  child: InkWell(
                    child: TextButton.icon(
                      onPressed: _addStop,
                      icon: const Icon(Icons.add, color: Colors.blue,),
                      label: const Text('Add Stop', style: TextStyle(color: Colors.blue),),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black),),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.routeCode == null ? 'Add' : 'Save', style: TextStyle(color: Colors.blue),),
        ),
      ],
    );
  }

  Widget _buildStopField(int index, StopController stop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stop ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_stops.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    onPressed: () => _removeStop(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: stop.nameController,
              decoration: const InputDecoration(
                labelText: 'Stop Name',
                hintText: 'e.g., Ayala Center',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Stop name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: stop.latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '10.3157',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: stop.lngController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '123.8854',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}