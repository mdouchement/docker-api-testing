module Docker
  module Testing
    class ContainerManager
      def perform(http_method, path, query, opts, &block)
        #puts "http_method: #{ http_method }, path: #{ path }, query: #{ query }, opts: #{ opts }"

        # /containers/5453685454/start => ['containers, '5453685454', 'start']
        splits = path.split('/')[1..-1]

        if splits.length == 3
          send("#{ http_method }_#{ splits[2] }_with_id".downcase, splits[1][0..12], query, opts)
        else
          # remove: DELETE /containers/#{self.id}
          # all: GET /containers/json
          if http_method == :delete && (id = path.match(%r{/containers/(.*)}))
            delete(id[1])
          else
            send("#{ http_method }_#{ splits.last }".downcase, path, query, opts)
          end
        end
      end

      private

      def containers
        @containers ||= {}
      end

      def stoped_containers
        @stoped_containers ||= {}
      end

      # create container
      def post_create(_, query, opts)
        id = SecureRandom.hex(32)
        containers["#{ id[0..12] }"] = EmulatedContainer.new(id, query, opts)
        response(id)
      end

      # start container
      def post_start_with_id(id, _, opts)
        if stoped_containers[id]
          containers[id] = stoped_containers.delete(id)
          containers[id].state('FinishedAt' => '0001-01-01T00:00:00Z')
          containers[id].define_pid
        end

        containers[id].tap do |container|
          container.define_pulic_ports(opts[:body].delete('PortBindings'))
          container.host_config(opts[:body])
          container.state('StartedAt' => Testing.time_now, 'Running' => true)
          container.define_pid if container.pid == 0
        end
        response(id)
      end
      alias_method :post_attach_with_id, :post_start_with_id

      # stop container
      def post_stop_with_id(id, _, opts)
        return response(id) unless containers[id]

        containers[id].tap do |container|
          container.host_config(opts[:body])
          container.state('FinishedAt' => Testing.time_now, 'Running' => false)
        end
        stoped_containers[id] = containers.delete(id)
        response(id)
      end

      # restart container
      def post_restart_with_id(id, query, opts)
        # restart have no options
        opts = { body: {} }

        post_stop_with_id(id, query, opts) if containers[id]

        if stoped_containers[id]
          post_start_with_id(id, query, opts)
        else
          fail Error::NotFoundError.new('Expected(200..204) <=> Actual(404 Not Found)')
        end

        response(id)
      end

      # container top (basic result)
      def get_top_with_id(id, _, _)
        container = containers[id]

        {
          'Processes' => [
            [container.user, container.pid, container.ppid, '0',
             Time.now.strftime('%H:%M'), container.tty_name, '00:00:00', container.command]
          ],
          'Titles' => %w(UID PID PPID C STIME TTY TIME CMD)
        }
      end

      # pause container
      def post_pause_with_id(id, _, _)
        containers[id].tap do |container|
          container.state('Paused' => true)
        end

        response(id)
      end

      # unpause container
      def post_unpause_with_id(id, _, _)
        containers[id].tap do |container|
          container.state('Paused' => false)
        end

        response(id)
      end

      # kill container
      def post_kill_with_id(id, _, opts)
        containers[id].tap do |container|
          container.host_config(opts[:body])
          container.state('ExitCode' => -1, 'FinishedAt' => Testing.time_now, 'Running' => false)
        end
        stoped_containers[id] = containers.delete(id)
        response(id)
      end

      # get container
      def get_json_with_id(id, _, _)
        if containers.key?(id)
          containers[id].template
        elsif stoped_containers.key?(id)
          stoped_containers[id].template
        else
          fail Docker::Error::NotFoundError.new('Expected([200, 201, 202, 203, 204, 304]) ' \
                                                '<=> Actual(404 Not Found)')
        end
      end

      # get all containers
      def get_json(*_)
        containers.values.map do |container|
          tpt = container.template

          {
            'Command' => container.command,
            'Created' => Time.parse(tpt['Created']).to_i,
            'Id' => tpt['id'],
            'Image' => tpt['Image'],
            'Names' => [tpt['Name']],
            'Ports' => container.ports_details,
            'Status' => 'Up Less than a second'# Write method that define this
          }
        end
      end

      # wait container
      def get_wait_with_id(*_)
        { 'StatusCode' => 0 }
      end

      # container's logs
      def get_logs_with_id(*_)
        fail 'Unsupported'
      end

      # container's changes
      def get_changes_with_id(*_)
        fail 'Unsupported'
      end

      # container's changes
      def get_copy_with_id(*_)
        fail 'Unsupported'
      end

      # export container
      def get_export_with_id(*_)
        fail 'Unsupported'
      end

      # attach container
      def get_attach_with_id(*_)
        fail 'Unsupported'
      end

      # remove container
      def delete(id)
        short_id = id[0..12]

        if containers.key?(short_id)
          fail ::Excon::Errors::NotAcceptable.new('Expected(200..204) ' \
                                                  '<=> Actual(406 Not Acceptable)')
        end

        unless stoped_containers.key?(short_id)
          fail Docker::Error::NotFoundError.new('Expected(200..204) <=> Actual(404 Not Found)')
        end

        stoped_containers.delete(short_id)
        nil
      end

      # Warnings value is nil or it is an array
      def response(id)
        { 'Id' => id, 'Warnings' => nil }
      end
    end
  end
end
