/**
 * Surya Connect — Google Apps Script REST API
 * Bind this script to your spreadsheet:
 * https://docs.google.com/spreadsheets/d/17Ykb2oV_QgkqzOlEilF2feZi6Xs_TBnoN-RY2iOhnOo/edit
 *
 * Deploy: Deploy > New deployment > Web app
 * Execute as: Me | Who has access: Anyone
 *
 * Optional: set MEDIA_FOLDER_ID in Script Properties for photo uploads
 */
var CONFIG = {
  ADMIN_PASSWORD: 'SURYA123',
  TOKEN_SECRET: 'surya-connect-secret-change-in-production',
  MEDIA_FOLDER_ID: '', // paste Google Drive folder ID
  SHEETS: {
    students: 'Students',
    classes: 'Classes',
    feePayments: 'FeePayments',
    attendance: 'Attendance',
    tests: 'Tests',
    testResults: 'TestResults',
    gallery: 'Gallery',
    staff: 'Staff',
    config: 'Config'
  }
};

var HEADERS = {
  Students: ['studentId','name','class','section','dob','admissionDate','fatherName','fatherPhone','fatherEmail','motherName','motherPhone','motherEmail','address','aadharNo','totalFees','profilePhotoUrl','active'],
  Classes: ['classId','name','section','academicYear','active'],
  FeePayments: ['paymentId','paymentDate','studentId','studentName','amountPaid','method','remarks'],
  Attendance: ['date','studentId','studentName','classId','status'],
  Tests: ['testId','classId','testName','subject','testDate','maxMarks','active'],
  TestResults: ['resultId','testId','studentId','marks','grade'],
  Gallery: ['itemId','date','type','title','url','thumbnailUrl'],
  Staff: ['staffId','name','designation','phone','email','profilePhotoUrl','classIds','salary','active'],
  Config: ['key','value']
};

function doGet(e) { return handleRequest(e, 'GET'); }
function doPost(e) { return handleRequest(e, 'POST'); }

function handleRequest(e, method) {
  try {
    ensureSheets();
    var path = (e.parameter.path || '/').replace(/^\//, '');
    var token = getTokenFromRequest_(e);

    if (path === 'sync') {
      var role = e.parameter.role || 'admin';
      var phone = normalizePhone_(e.parameter.phone || '');
      requireToken_(token, role, phone);
      return jsonOk(buildSync_(role, phone));
    }

    if (method === 'POST') {
      var body = parseBody_(e);
      path = body.path || path;

      if (path === 'auth/admin') {
        if (body.password !== CONFIG.ADMIN_PASSWORD) throw new Error('Invalid admin password');
        return jsonOk({ token: mintToken_('admin', ''), role: 'admin' });
      }
      if (path === 'auth/parent') {
        var pPhone = normalizePhone_(body.phone || '');
        var ids = findStudentsByPhone_(pPhone);
        if (!ids.length) throw new Error('No student linked to this phone number');
        return jsonOk({ token: mintToken_('parent', pPhone), role: 'parent', studentIds: ids });
      }
      if (path === 'media/upload') {
        requireAdmin_(token);
        var url = uploadMedia_(body.fileName, body.mimeType, body.data);
        return jsonOk({ url: url });
      }

      requireAdmin_(token);
      var action = body.action || 'create';
      var data = body.data || {};
      var id = body.id || '';

      if (path === 'students') return jsonOk(handleStudents_(action, id, data));
      if (path === 'classes') return jsonOk(handleClasses_(action, id, data));
      if (path === 'fees') return jsonOk(handleFees_(action, id, data));
      if (path === 'attendance') return jsonOk(handleAttendance_(action, id, data));
      if (path === 'tests') return jsonOk(handleTests_(action, id, data));
      if (path === 'results') return jsonOk(handleResults_(action, id, data));
      if (path === 'gallery') return jsonOk(handleGallery_(action, id, data));
      if (path === 'staff') return jsonOk(handleStaff_(action, id, data));
    }

    throw new Error('Unknown route: ' + path);
  } catch (err) {
    return jsonErr(String(err.message || err));
  }
}

function ensureSheets() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  Object.keys(HEADERS).forEach(function(name) {
    var sheet = ss.getSheetByName(name);
    if (!sheet) sheet = ss.insertSheet(name);
    if (sheet.getLastRow() === 0) sheet.appendRow(HEADERS[name]);
  });
  var config = ss.getSheetByName('Config');
  if (config.getLastRow() <= 1) {
    config.appendRow(['adminPassword', CONFIG.ADMIN_PASSWORD]);
  }
}

function getSheetRows_(sheetName) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName);
  var values = sheet.getDataRange().getValues();
  if (values.length <= 1) return [];
  var headers = values[0];
  var rows = [];
  for (var i = 1; i < values.length; i++) {
    var obj = {};
    for (var j = 0; j < headers.length; j++) obj[headers[j]] = values[i][j];
    rows.push(obj);
  }
  return rows;
}

function appendRow_(sheetName, obj) {
  var headers = HEADERS[sheetName];
  var row = headers.map(function(h) { return obj[h] !== undefined ? obj[h] : ''; });
  SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName).appendRow(row);
}

function updateRowById_(sheetName, idField, idValue, obj) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName);
  var values = sheet.getDataRange().getValues();
  var headers = values[0];
  var idCol = headers.indexOf(idField);
  for (var i = 1; i < values.length; i++) {
    if (String(values[i][idCol]) === String(idValue)) {
      headers.forEach(function(h, j) {
        if (obj[h] !== undefined) sheet.getRange(i + 1, j + 1).setValue(obj[h]);
      });
      return true;
    }
  }
  return false;
}

function deleteRowById_(sheetName, idField, idValue) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName);
  var values = sheet.getDataRange().getValues();
  var headers = values[0];
  var idCol = headers.indexOf(idField);
  for (var i = values.length - 1; i >= 1; i--) {
    if (String(values[i][idCol]) === String(idValue)) {
      sheet.deleteRow(i + 1);
      return true;
    }
  }
  return false;
}

function nextId_(prefix, sheetName, idField) {
  var rows = getSheetRows_(sheetName);
  var max = 0;
  rows.forEach(function(r) {
    var id = String(r[idField] || '');
    var m = id.match(new RegExp('^' + prefix + '(\\d+)$'));
    if (m) max = Math.max(max, parseInt(m[1], 10));
  });
  return prefix + String(max + 1).padStart(3, '0');
}

function normalizePhone_(phone) {
  return String(phone || '').replace(/\D/g, '').slice(-10);
}

function findStudentsByPhone_(phone) {
  return getSheetRows_('Students').filter(function(s) {
    return normalizePhone_(s.fatherPhone) === phone || normalizePhone_(s.motherPhone) === phone;
  }).map(function(s) { return String(s.studentId); });
}

function buildSync_(role, phone) {
  var students = getSheetRows_('Students');
  var classes = getSheetRows_('Classes');
  var feePayments = getSheetRows_('FeePayments');
  var attendance = getSheetRows_('Attendance');
  var tests = getSheetRows_('Tests');
  var testResults = getSheetRows_('TestResults');
  var gallery = getSheetRows_('Gallery');
  var staff = getSheetRows_('Staff');

  if (role === 'parent') {
    var ids = findStudentsByPhone_(phone);
    students = students.filter(function(s) { return ids.indexOf(String(s.studentId)) >= 0; });
    var idSet = {};
    ids.forEach(function(id) { idSet[id] = true; });
    feePayments = feePayments.filter(function(p) { return idSet[String(p.studentId)]; });
    attendance = attendance.filter(function(a) { return idSet[String(a.studentId)]; });
    testResults = testResults.filter(function(r) { return idSet[String(r.studentId)]; });
    staff = staff.map(function(s) {
      return { staffId: s.staffId, name: s.name, designation: s.designation, profilePhotoUrl: s.profilePhotoUrl, classIds: s.classIds, active: s.active };
    });
    return {
      students: students,
      classes: classes,
      feePayments: feePayments,
      attendance: attendance,
      tests: tests,
      testResults: testResults,
      gallery: gallery,
      staff: staff,
      linkedStudentIds: ids
    };
  }

  return {
    students: students,
    classes: classes,
    feePayments: feePayments,
    attendance: attendance,
    tests: tests,
    testResults: testResults,
    gallery: gallery,
    staff: staff,
    linkedStudentIds: []
  };
}

function handleStudents_(action, id, data) {
  if (action === 'create') {
    var newId = nextId_('S', 'Students', 'studentId');
    appendRow_('Students', Object.assign({}, data, { studentId: newId, active: data.active !== false }));
    return { studentId: newId };
  }
  if (action === 'update') {
    updateRowById_('Students', 'studentId', id, data);
    return { studentId: id };
  }
  if (action === 'delete') {
    deleteRowById_('Students', 'studentId', id);
    return { deleted: id };
  }
  throw new Error('Unknown students action');
}

function handleClasses_(action, id, data) {
  if (action === 'create') {
    var classId = data.name + '-' + data.section;
    appendRow_('Classes', {
      classId: classId,
      name: data.name,
      section: data.section,
      academicYear: data.academicYear || '2025-2026',
      active: true
    });
    return { classId: classId };
  }
  if (action === 'delete') {
    deleteRowById_('Classes', 'classId', id);
    return { deleted: id };
  }
  throw new Error('Unknown classes action');
}

function handleFees_(action, id, data) {
  if (action === 'create') {
    var paymentId = nextId_('PAY', 'FeePayments', 'paymentId');
    appendRow_('FeePayments', Object.assign({}, data, { paymentId: paymentId }));
    return { paymentId: paymentId };
  }
  throw new Error('Unknown fees action');
}

function handleAttendance_(action, id, data) {
  if (action === 'upsert') {
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Attendance');
    var values = sheet.getDataRange().getValues();
    if (values.length <= 1) {
      appendRow_('Attendance', data);
      return { ok: true };
    }
    var headers = values[0];
    var dateCol = headers.indexOf('date');
    var studentCol = headers.indexOf('studentId');
    for (var i = 1; i < values.length; i++) {
      if (String(values[i][dateCol]) === String(data.date) &&
          String(values[i][studentCol]) === String(data.studentId)) {
        headers.forEach(function(h, j) {
          if (data[h] !== undefined) sheet.getRange(i + 1, j + 1).setValue(data[h]);
        });
        return { ok: true };
      }
    }
    appendRow_('Attendance', data);
    return { ok: true };
  }
  throw new Error('Unknown attendance action');
}

function handleTests_(action, id, data) {
  if (action === 'create') {
    var testId = nextId_('T', 'Tests', 'testId');
    appendRow_('Tests', Object.assign({}, data, { testId: testId, active: true }));
    return { testId: testId };
  }
  throw new Error('Unknown tests action');
}

function handleResults_(action, id, data) {
  if (action === 'upsert') {
    var resultId = data.testId + '_' + data.studentId;
    var rows = getSheetRows_('TestResults');
    var exists = rows.some(function(r) {
      return String(r.resultId) === resultId;
    });
    if (exists) {
      updateRowById_('TestResults', 'resultId', resultId, data);
    } else {
      appendRow_('TestResults', Object.assign({}, data, { resultId: resultId }));
    }
    return { resultId: resultId };
  }
  throw new Error('Unknown results action');
}

function handleGallery_(action, id, data) {
  if (action === 'create') {
    var itemId = nextId_('G', 'Gallery', 'itemId');
    appendRow_('Gallery', Object.assign({}, data, { itemId: itemId }));
    return { itemId: itemId };
  }
  throw new Error('Unknown gallery action');
}

function handleStaff_(action, id, data) {
  if (action === 'create') {
    var staffId = nextId_('ST', 'Staff', 'staffId');
    appendRow_('Staff', Object.assign({}, data, { staffId: staffId, active: true }));
    return { staffId: staffId };
  }
  if (action === 'update') {
    updateRowById_('Staff', 'staffId', id, data);
    return { staffId: id };
  }
  if (action === 'delete') {
    deleteRowById_('Staff', 'staffId', id);
    return { deleted: id };
  }
  throw new Error('Unknown staff action');
}

function uploadMedia_(fileName, mimeType, base64Data) {
  var folderId = CONFIG.MEDIA_FOLDER_ID || PropertiesService.getScriptProperties().getProperty('MEDIA_FOLDER_ID');
  if (!folderId) throw new Error('Set MEDIA_FOLDER_ID in Script Properties for photo uploads');
  var blob = Utilities.newBlob(Utilities.base64Decode(base64Data), mimeType, fileName);
  var file = DriveApp.getFolderById(folderId).createFile(blob);
  file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  return 'https://drive.google.com/uc?export=view&id=' + file.getId();
}

function mintToken_(role, phone) {
  var expiry = Date.now() + 1000 * 60 * 60 * 24 * 7;
  var payload = role + '|' + phone + '|' + expiry;
  var sig = Utilities.base64EncodeWebSafe(
    Utilities.computeHmacSha256Signature(payload, CONFIG.TOKEN_SECRET)
  );
  return Utilities.base64EncodeWebSafe(payload + '::' + sig);
}

function getTokenFromRequest_(e) {
  if (e.parameter && e.parameter.token) return e.parameter.token;
  if (e.postData && e.postData.contents) {
    try {
      var body = JSON.parse(e.postData.contents);
      if (body.token) return body.token;
    } catch (err) {}
  }
  return '';
}

function parseBody_(e) {
  if (!e.postData || !e.postData.contents) return {};
  return JSON.parse(e.postData.contents);
}

function requireToken_(token, role, phone) {
  if (!token) throw new Error('Missing auth token');
  verifyToken_(token, role, phone);
}

function requireAdmin_(token) {
  if (!token) throw new Error('Missing auth token');
  verifyToken_(token, 'admin', '');
}

function verifyToken_(token, expectedRole, expectedPhone) {
  try {
    var decoded = Utilities.newBlob(Utilities.base64DecodeWebSafe(token)).getDataAsString();
    var splitAt = decoded.indexOf('::');
    if (splitAt < 0) throw new Error('Invalid token');
    var payload = decoded.substring(0, splitAt);
    var sigStr = decoded.substring(splitAt + 2);
    var expectedSig = Utilities.base64EncodeWebSafe(
      Utilities.computeHmacSha256Signature(payload, CONFIG.TOKEN_SECRET)
    );
    if (sigStr !== expectedSig) throw new Error('Invalid signature');
    var parts = payload.split('|');
    var role = parts[0];
    var phone = parts[1];
    var expiry = parseInt(parts[2], 10);
    if (Date.now() > expiry) throw new Error('Token expired');
    if (expectedRole && role !== expectedRole) throw new Error('Invalid role');
    if (expectedRole === 'parent' && normalizePhone_(phone) !== normalizePhone_(expectedPhone)) {
      throw new Error('Invalid parent token');
    }
  } catch (e) {
    throw new Error('Unauthorized');
  }
}

function jsonOk(data) {
  return ContentService.createTextOutput(JSON.stringify({ ok: true, data: data }))
    .setMimeType(ContentService.MimeType.JSON);
}

function jsonErr(message) {
  return ContentService.createTextOutput(JSON.stringify({ ok: false, error: message }))
    .setMimeType(ContentService.MimeType.JSON);
}

/** Run once from editor to initialize sheet tabs and sample data */
function seedSampleData() {
  ensureSheets();
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  if (ss.getSheetByName('Students').getLastRow() > 1) return;
  appendRow_('Students', {
    studentId: 'S001', name: 'Aarav Verma', class: 'Nursery', section: 'A',
    dob: '2020-05-10', admissionDate: '2024-04-01',
    fatherName: 'Rohit Verma', fatherPhone: '9876543210', fatherEmail: 'rohit@email.com',
    motherName: 'Anita Verma', motherPhone: '9876543211', motherEmail: 'anita@email.com',
    address: 'Lucknow', aadharNo: '123456789012', totalFees: 24000,
    profilePhotoUrl: '', active: true
  });
  appendRow_('Classes', { classId: 'Nursery-A', name: 'Nursery', section: 'A', academicYear: '2025-2026', active: true });
}
