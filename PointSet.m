classdef PointSet < handle
    %POINTSET Summary of this class goes here
    %   Detailed explanation goes here
    properties
        X
        Clickable
    end
    properties(SetAccess = private)
        DragStartPoint
        isDragged
        DraggedPointID
    end
    properties(Access = private)
        Xi
        h_pointSet
        h_fig
        CID_ondrag
        CID_onbuttonup
        h_snap
    end
    
    methods
        function obj = PointSet(varargin)
            if nargin==0
                obj.X=zeros(2,0);
                options={};
            elseif nargin==1
                obj.X=varargin{1};
                options={};
            elseif nargin>1
                obj.X=varargin{1};
                options=varargin(2:end);
            end
            if isempty(obj.X)
                obj.X=zeros(2,0);
            end
            obj.h_pointSet=line('XData',obj.X(1,:),'YData',obj.X(2,:),options{:},...
                        'ButtonDownFcn',@(src,ev)oncontrolsdown(obj,src,ev));
                        
            obj.h_fig=gcf;
            obj.h_snap=[];
            obj.Clickable=true;
        end
        function delete(obj)
            if ishandle(obj.h_pointSet)
                delete(obj.h_pointSet);
            end
        end
        function set.Clickable(obj,flag)
            if flag
                set(obj.h_pointSet,'HitTest','on');
            else
                set(obj.h_pointSet,'HitTest','off');
            end
        end
        function set.X(obj,X)
            obj.X=X;
            if isempty(X)
                obj.X=zeros(2,0);
            end
            set(obj.h_pointSet,'XData',obj.X(1,:)','YData',obj.X(2,:)');
        end
        function X=get.X(obj)
            X=obj.X;
        end
        function AddPoint(obj,X_new)
            if ~isempty(obj.h_snap)
                if verLessThan('matlab','8.4')
                    [~,X,V,~] = vertexpicker(obj.h_snap,[X_new',100;X_new',-100],'-force');
                    X_new=X(1:2)';
                else
                    [pout,vout,viout,pfactor,facevout] = vertexpicker(obj.h_snap,[X_new',100;X_new',-100],'-force');
                    X_new=obj.h_snap.Vertices(viout,1:2)';
                end
                
                
            end
            obj.X=[obj.X, X_new];
        end
        function RemovePoint(obj,Xi_remove)
            obj.X(:,Xi_remove)=[];
            notify(obj,'PointRemoved');
        end
        function Clear(obj)
            obj.X=zeros(2,0);
        end
        function Visible(obj,flag)
            set(obj.h_pointSet,'Visible',flag);
        end
        function SetSnap(obj,h_snap)
            obj.h_snap=h_snap;
        end
        function ClearSnap(obj)
            obj.h_snap=[];
        end
        function oncontrolsdown(obj,src,ev)
            obj.CID_onbuttonup=iptaddcallback(obj.h_fig,'WindowButtonUpFcn',@(src,ev)oncontrolsup(obj,src,ev));
            obj.DragStartPoint=get(gca,'currentpoint');
            obj.DragStartPoint=obj.DragStartPoint(1,1:2)';
            [~,obj.Xi]=min(sum((obj.X-repmat(obj.DragStartPoint,1,size(obj.X,2))).^2,1));
            obj.DraggedPointID=obj.Xi;
            switch get(gcf,'selectionType')
                case {'normal','alt'}
                    obj.CID_ondrag=iptaddcallback(obj.h_fig,'WindowButtonMotionFcn',@(src,ev)ondrag(obj,src,ev));
                    obj.isDragged=true;
                case 'open' %double click
                    obj.RemovePoint(obj.Xi);
            end
        end
        function oncontrolsup(obj,src,ev)
            if ~isempty(obj.h_snap)
                down_pos=get(gca,'currentpoint');
                if verLessThan('matlab','8.4')
                    [~,X,V,~] = vertexpicker(obj.h_snap,down_pos,'-force');
                    obj.X(:,obj.Xi)=X(1:2)';
                else
                    [pout,vout,viout,pfactor,facevout] = vertexpicker(obj.h_snap,down_pos,'-force');
                    obj.X(:,obj.Xi)=obj.h_snap.Vertices(viout,1:2)';
                end
            end
            iptremovecallback(obj.h_fig,'WindowButtonUpFcn',obj.CID_onbuttonup);
            iptremovecallback(obj.h_fig,'WindowButtonMotionFcn',obj.CID_ondrag);
            notify(obj,'PointDropped');
            obj.isDragged=false;
            obj.DraggedPointID=[];
            obj.DragStartPoint=[];
        end
        function ondrag(obj,src,ev)
            iptremovecallback(obj.h_fig,'WindowButtonMotionFcn',obj.CID_ondrag);
            down_pos=get(gca,'currentpoint');
            switch get(gcf,'selectionType')
                case 'normal'
                    obj.X(:,obj.Xi)=down_pos(1,1:2)';
                case 'alt'  % in windows this is 'control'
%                     obj.DragStartPoint=down_pos;
            end
            obj.CID_ondrag=iptaddcallback(obj.h_fig,'WindowButtonMotionFcn',@(src,ev)ondrag(obj,src,ev));
            notify(obj,'PointDragged');
        end
        function newobj = horzcat(varargin)
            newobj=PointSet(cell2mat(cellfun(@(s)s.X,varargin,'UniformOutput',0)));
            newobj.Angle=cell2mat(cellfun(@(s)s.Angle,varargin,'UniformOutput',0));
        end
        function newobj = vertcat(varargin)
            newobj=horzcat(varargin);
        end
    end
    events
        PointPicked
        PointDragged
        PointDropped
        PointRemoved
    end
end



