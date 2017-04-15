function publishSlides(html_file,destination_folder)
%
% @param html_file path to the main slide file location
% @param destination_folder path to the folder in which to write the file
% and results.  

% todo: add option to make youtube links appear first when possible, for
% publishing online.  or to ONLY include youtube links when they are
% available.

% todo: consider scrapping the xml parser and just doing the simple text
% parsing for the src strings.  have to decide if it's morally better to
% produce accurate good xml/html files or if it's too much of a burden.

if nargin<2,
  error('Usage: publishSlides(html_file,destination_folder)');
end
if any(destination_folder=='~')
  error('don''t use ~ in the folder name.');  % could handle this case, but i'm tired.
end
if exist(destination_folder,'dir')
  fprintf('The folder %s exists and will be deleted.\nHit ctrl-c to cancel, or any other key to continue\n',destination_folder);
  pause;
  rmdir(destination_folder,'s');
end
mkdir(destination_folder);

[filepath,file,ext] = fileparts(html_file);
if ~isempty(filepath), cd(filepath); end
html_file = [file,ext];

doc = xmlread(html_file);

replaceSRCElements(doc.getElementsByTagName('img'),destination_folder);
replaceSRCElements(doc.getElementsByTagName('image'),destination_folder);
replaceSRCElements(doc.getElementsByTagName('video'),destination_folder);
replaceSRCElements(doc.getElementsByTagName('source'),destination_folder);

scripts = doc.getElementsByTagName('script');
for i=0:(scripts.getLength()-1)
  if ~scripts.item(i).hasChildNodes
    % safari doesn't like <script />, so i have to artificially add empty text
    % to make sure I get <script> </script>.  sigh.
    node = doc.createTextNode(' ');
    scripts.item(i).appendChild(node);
  else
    txt = char(scripts.item(i).getChildNodes.item(0).getNodeValue());
    % replace embedded swfs
    if strfind(txt,'embedSWF')
      file=regexp(txt,'embedSWF("([^"]*)"','tokens'); 
      file=file{1}{1};
      newfile = makeLocalCopy(file,destination_folder);
      txt = strrep(txt,file,newfile);
      scripts.item(i).getChildNodes.item(0).setNodeValue(txt);
    end
  end
end

xmlwrite(fullfile(destination_folder,html_file),doc);

end

function replaceSRCElements(node_list,destination_folder)

for i=0:(node_list.getLength()-1)
  node = node_list.item(i);
  if node.hasAttribute('src')
    node.setAttribute('src',makeLocalCopy(char(node.getAttribute('src')),destination_folder));
  end
end

end

function new_filename = makeLocalCopy(filename,destination_folder)
  pound = find(filename=='#'); if ~isempty(pound) filename = filename(1:pound(1)-1); end
  if strncmpi(filename,'http://',7)
    new_filename = filename; 
    return;
  end
  [path,file,ext] = fileparts(filename);
  new_filename = [file,ext];
  copyfile(filename,fullfile(destination_folder,new_filename));
end