
module.exports.readVersion = function (contents) {
  const regex = /\d+\.\d+\.\d+/g;
  const found = contents.match(regex);
  console.log(found);
  return found[0];
}

module.exports.writeVersion = function (contents, version) {
  const regex = /\d+\.\d+\.\d+/g;
  return contents.replace(regex, version);
}
